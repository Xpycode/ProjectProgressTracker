//
//  ProgressPersistence.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import CryptoKit

/// Structure to represent saved checkbox states and collapse states
struct SavedProgress: Codable {
    let filename: String
    let savedAt: Date
    let checkboxStates: [String: Bool] // String ID to checked state
    let expandedHeaders: Set<String> // String IDs of expanded headers
    
    enum CodingKeys: String, CodingKey {
        case filename
        case savedAt
        case checkboxStates
        case expandedHeaders
    }
}

extension SavedProgress {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filename = try container.decode(String.self, forKey: .filename)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        checkboxStates = try container.decode([String: Bool].self, forKey: .checkboxStates)
        
        // Handle the case where expandedHeaders might not exist in older saved files
        expandedHeaders = (try? container.decode(Set<String>.self, forKey: .expandedHeaders)) ?? []
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
        for item in document.checkboxItems {
            checkboxStates[item.id] = item.isChecked
        }
        
        let expandedHeaderIDs = document.expandedHeaders
        
        let savedProgress = SavedProgress(
            filename: document.filename,
            savedAt: Date(),
            checkboxStates: checkboxStates,
            expandedHeaders: Set(expandedHeaderIDs)
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
    
    /// Apply loaded checkbox states to parsed items
    func applyProgressToItems(_ items: inout [ContentItem], savedStates: [String: Bool]) {
        for (index, item) in items.enumerated() {
            if item.type == .checkbox, let savedCheckedState = savedStates[item.id] {
                items[index] = item.withCheckedState(savedCheckedState)
            }
        }
    }
}