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
            // Fallback to original directory if we can't access Application Support
            print("Failed to access Application Support directory: \(error)")
            let fileName = markdownFileURL.deletingPathExtension().lastPathComponent
            let progressFileName = "\(fileName).progress.json"
            return markdownFileURL.deletingLastPathComponent().appendingPathComponent(progressFileName)
        }
    }
    
    /// Save checkbox states and collapse states to a progress file
    func saveProgress(for document: Document, markdownFileURL: URL) -> Bool {
        let progressFileURL = getProgressFileURL(for: markdownFileURL)
        print("DEBUG: Saving progress to \(progressFileURL.path)")
        
        // Create dictionary of checkbox states using String IDs directly
        var checkboxStates: [String: Bool] = [:]
        for item in document.checkboxItems {
            checkboxStates[item.id] = item.isChecked
        }
        
        print("DEBUG: Saving checkbox states: \(checkboxStates)")
        
        // Create set of expanded header IDs using String IDs directly
        let expandedHeaderIDs = document.expandedHeaders
        print("DEBUG: Saving expanded headers: \(expandedHeaderIDs)")
        
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
            print("Progress saved to \(progressFileURL.path)")
            return true
        } catch {
            print("Failed to save progress: \(error)")
            return false
        }
    }
    
    /// Load checkbox states and collapse states from a progress file
    func loadProgress(for markdownFileURL: URL) -> SavedProgress? {
        let progressFileURL = getProgressFileURL(for: markdownFileURL)
        print("DEBUG: Attempting to load progress from \(progressFileURL.path)")
        
        // Check if progress file exists
        guard FileManager.default.fileExists(atPath: progressFileURL.path) else {
            print("No progress file found at \(progressFileURL.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: progressFileURL)
            let savedProgress = try JSONDecoder().decode(SavedProgress.self, from: data)
            print("Progress loaded from \(progressFileURL.path)")
            print("DEBUG: Loaded checkbox states: \(savedProgress.checkboxStates)")
            print("DEBUG: Loaded expanded headers: \(savedProgress.expandedHeaders)")
            return savedProgress
        } catch {
            print("Failed to load progress: \(error)")
            return nil
        }
    }
    
    /// Apply loaded checkbox states to parsed items
    func applyProgressToItems(_ items: inout [ContentItem], savedStates: [String: Bool]) {
        print("DEBUG: === APPLYING PROGRESS ===")
        print("DEBUG: Saved states count: \(savedStates.count)")
        print("DEBUG: Saved states: \(savedStates)")
        print("DEBUG: Current items count: \(items.count)")
        print("DEBUG: Current item IDs: \(items.map { $0.id })")
        
        var appliedCount = 0
        for (index, item) in items.enumerated() {
            if item.type == .checkbox {
                print("DEBUG: Processing checkbox at index \(index), ID: \(item.id), current state: \(item.isChecked)")
                
                if let savedCheckedState = savedStates[item.id] {
                    print("DEBUG: Found saved state for \(item.id): \(savedCheckedState)")
                    
                    // Create a new item with the saved state BUT PRESERVE THE ORIGINAL ID
                    let updatedItem = item.withCheckedState(savedCheckedState)
                    items[index] = updatedItem
                    appliedCount += 1
                    print("DEBUG: Updated item \(item.id) to \(savedCheckedState)")
                    print("DEBUG: Verified ID preserved: \(item.id == updatedItem.id)")
                } else {
                    print("DEBUG: No saved state found for \(item.id)")
                }
            }
        }
        print("DEBUG: Applied \(appliedCount) checkbox state updates")
        print("DEBUG: === FINISHED APPLYING PROGRESS ===")
    }
}