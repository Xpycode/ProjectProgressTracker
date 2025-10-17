//
//  ProgressPersistence.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import CryptoKit

/// Represents a storable snapshot of a ContentItem for reconciliation.
struct SavedItem: Codable, Hashable {
    let id: String
    let type: ItemType
    let text: String
    let level: Int
    let indentationLevel: Int
    let position: Int
}

/// Structure to represent saved checkbox states and collapse states
struct SavedProgress: Codable {
    let filename: String
    let savedAt: Date
    let checkboxStates: [String: Bool] // String ID to checked state
    let expandedHeaders: Set<String> // String IDs of expanded headers
    let items: [SavedItem]? // A snapshot of items for fuzzy matching. Optional for backward compatibility.

    enum CodingKeys: String, CodingKey {
        case filename
        case savedAt
        case checkboxStates
        case expandedHeaders
        case items
    }
}

extension SavedProgress {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filename = try container.decode(String.self, forKey: .filename)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        checkboxStates = try container.decode([String: Bool].self, forKey: .checkboxStates)

        // Handle optional properties for backward compatibility
        expandedHeaders = (try? container.decode(Set<String>.self, forKey: .expandedHeaders)) ?? []
        items = (try? container.decode([SavedItem].self, forKey: .items))
    }
}

class ProgressPersistence {
    static let shared = ProgressPersistence()

    private init() {}

    /// Get the Application Support directory URL
    private func getApplicationSupportDirectory() throws -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[0].appendingPathComponent("ProjectProgressTracker")

        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        }

        return appSupportURL
    }

    /// Get the progress directory URL
    private func getProgressDirectory() throws -> URL {
        let appSupportURL = try getApplicationSupportDirectory()
        let progressURL = appSupportURL.appendingPathComponent("progress")

        // Create the progress directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: progressURL.path) {
            try fileManager.createDirectory(at: progressURL, withIntermediateDirectories: true, attributes: nil)
        }

        return progressURL
    }

    /// Generate a unique identifier for a markdown file based on its path
    private func getUniqueIdentifier(for markdownFileURL: URL) -> String {
        // Use the full path as the basis for the identifier
        let fullPath = markdownFileURL.path
        // Create a hash of the full path to ensure uniqueness
        let hashedPath = fullPath.data(using: .utf8)?.sha256().hexEncodedString() ?? fullPath
        return hashedPath
    }

    /// Get the progress file URL for a given markdown file
    func getProgressFileURL(for markdownFileURL: URL) -> URL {
        do {
            let progressDirectory = try getProgressDirectory()
            let uniqueIdentifier = getUniqueIdentifier(for: markdownFileURL)
            let progressFileName = "\(uniqueIdentifier).progress.json"
            return progressDirectory.appendingPathComponent(progressFileName)
        } catch {
            let fileName = markdownFileURL.deletingPathExtension().lastPathComponent
            let progressFileName = "\(fileName).progress.json"
            return markdownFileURL.deletingLastPathComponent().appendingPathComponent(progressFileName)
        }
    }

    /// Save checkbox states and collapse states to a progress file
    func saveProgress(for document: Document, markdownFileURL: URL) -> Bool {
        let progressFileURL = getProgressFileURL(for: markdownFileURL)

        var checkboxStates: [String: Bool] = [:]
        var savedItems: [SavedItem] = []

        // We now save both the states and a snapshot of the items
        for item in document.items {
            if item.type == .checkbox {
                checkboxStates[item.id] = item.isChecked
            }
            savedItems.append(SavedItem(
                id: item.id,
                type: item.type,
                text: item.text,
                level: item.level,
                indentationLevel: item.indentationLevel,
                position: item.position
            ))
        }

        let expandedHeaderIDs = document.expandedHeaders

        let savedProgress = SavedProgress(
            filename: document.filename,
            savedAt: Date(),
            checkboxStates: checkboxStates,
            expandedHeaders: Set(expandedHeaderIDs),
            items: savedItems
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(savedProgress)
            try data.write(to: progressFileURL)
            return true
        } catch {
            return false
        }
    }

    /// Load checkbox states and collapse states from a progress file
    func loadProgress(for markdownFileURL: URL) -> SavedProgress? {
        let progressFileURL = getProgressFileURL(for: markdownFileURL)

        guard FileManager.default.fileExists(atPath: progressFileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: progressFileURL)
            let savedProgress = try JSONDecoder().decode(SavedProgress.self, from: data)
            return savedProgress
        } catch {
            return nil
        }
    }

    /// Reconciles newly parsed items with saved progress to preserve IDs and states.
    func reconcile(
        newItems: [ContentItem],
        with savedProgress: SavedProgress?
    ) -> (reconciledItems: [ContentItem], reconciledExpandedHeaders: Set<String>) {
        guard let savedProgress = savedProgress else {
            return (newItems, Set<String>())
        }

        // For modern progress files that include the item snapshot for matching
        if let oldItems = savedProgress.items {
            var availableOldItems = oldItems
            var finalItems = [ContentItem]()
            var preservedOldIDs = Set<String>()

            for newItem in newItems {
                let (bestMatch, bestScore) = findBestMatch(for: newItem, in: availableOldItems)

                if let match = bestMatch, bestScore >= 0.7 { // Confidence threshold of 70%
                    // A good match was found, so we preserve the old ID and state.
                    availableOldItems.removeAll { $0.id == match.id }
                    preservedOldIDs.insert(match.id)

                    let savedState = savedProgress.checkboxStates[match.id] ?? newItem.isChecked

                    // Create a new item with the new content but the old, stable ID.
                    let reconciledItem = ContentItem(
                        id: match.id,
                        type: newItem.type,
                        text: newItem.text,
                        level: newItem.level,
                        isChecked: savedState,
                        indentationLevel: newItem.indentationLevel,
                        position: newItem.position, // Use the new position
                        dueDate: newItem.dueDate
                    )
                    finalItems.append(reconciledItem)
                } else {
                    // No suitable match found, treat as a completely new item.
                    finalItems.append(newItem)
                }
            }

            // Preserve expanded state for headers whose IDs were successfully preserved.
            let reconciledExpandedHeaders = savedProgress.expandedHeaders.intersection(preservedOldIDs)

            return (finalItems, reconciledExpandedHeaders)

        } else {
            // Legacy mode for old progress files without item snapshots.
            // We can only apply states where the generated ID is an exact match.
            var updatedItems = newItems
            for (index, item) in updatedItems.enumerated() {
                if item.type == .checkbox, let savedCheckedState = savedProgress.checkboxStates[item.id] {
                    updatedItems[index] = item.withCheckedState(savedCheckedState)
                }
            }
            let currentIDs = Set(updatedItems.map { $0.id })
            let validExpanded = savedProgress.expandedHeaders.filter { currentIDs.contains($0) }
            return (updatedItems, Set(validExpanded))
        }
    }

    /// Finds the best matching `SavedItem` for a `ContentItem` from a list of candidates.
    private func findBestMatch(for newItem: ContentItem, in oldItems: [SavedItem]) -> (match: SavedItem?, score: Double) {
        var bestMatch: SavedItem? = nil
        var maxScore: Double = -1.0

        for oldItem in oldItems {
            // Basic structural properties must match.
            guard newItem.type == oldItem.type,
                  newItem.indentationLevel == oldItem.indentationLevel,
                  newItem.level == oldItem.level else {
                continue
            }

            // An exact text match is a perfect score.
            if newItem.text == oldItem.text {
                return (oldItem, 1.0)
            }

            // Calculate score based on text similarity (Levenshtein) and position proximity.
            let textDistance = levenshtein(newItem.text, oldItem.text)
            let maxLen = max(newItem.text.count, oldItem.text.count)
            let textSimilarity = maxLen == 0 ? 1.0 : 1.0 - (Double(textDistance) / Double(maxLen))

            // Penalize items that have moved significantly.
            let posDiff = abs(newItem.position - oldItem.position)
            let positionPenalty = min(Double(posDiff) * 0.05, 0.5) // Penalty capped at 0.5

            let score = textSimilarity - positionPenalty

            if score > maxScore {
                maxScore = score
                bestMatch = oldItem
            }
        }
        return (bestMatch, maxScore)
    }

    /// Calculates the Levenshtein distance between two strings.
    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aCount = a.count
        let bCount = b.count

        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        let aChars = Array(a)
        let bChars = Array(b)

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // Deletion
                    matrix[i][j-1] + 1,      // Insertion
                    matrix[i-1][j-1] + cost  // Substitution
                )
            }
        }

        return matrix[aCount][bCount]
    }
}
