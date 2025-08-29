//
//  ContentItem.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import CryptoKit

enum ItemType: String, CaseIterable {
    case header
    case checkbox
    case text
}

struct ContentItem: Identifiable {
    let id: String
    let type: ItemType
    let text: String
    let level: Int          // For headers (1-6)
    let isChecked: Bool     // For checkboxes
    let indentationLevel: Int
    
    init(type: ItemType, text: String, level: Int = 0, isChecked: Bool = false, indentationLevel: Int = 0, position: Int = 0) {
        self.type = type
        self.text = text
        self.level = level
        self.isChecked = isChecked
        self.indentationLevel = indentationLevel
        self.id = ContentItem.generateStableID(
            type: type,
            text: text,
            level: level,
            indentationLevel: indentationLevel,
            position: position
        )
        print("DEBUG: Created new ContentItem with ID: \(self.id) [Type: \(type), Text: '\(text)', Position: \(position)]")
    }
    
    /// Private initializer to create ContentItem with explicit ID (for preserving original IDs)
    private init(id: String, type: ItemType, text: String, level: Int, isChecked: Bool, indentationLevel: Int) {
        self.id = id
        self.type = type
        self.text = text
        self.level = level
        self.isChecked = isChecked
        self.indentationLevel = indentationLevel
        print("DEBUG: Created ContentItem with preserved ID: \(self.id)")
    }
    
    /// Create a copy of this ContentItem with updated checked state
    func withCheckedState(_ isChecked: Bool) -> ContentItem {
        print("DEBUG: Creating copy with updated state - Original ID: \(self.id), New State: \(isChecked)")
        let updatedItem = ContentItem(
            id: self.id,  // Preserve the original ID
            type: self.type,
            text: self.text,
            level: self.level,
            isChecked: isChecked,
            indentationLevel: self.indentationLevel
        )
        print("DEBUG: Copy created - Original ID: \(self.id), Updated ID: \(updatedItem.id), Match: \(self.id == updatedItem.id)")
        return updatedItem
    }
    
    /// Generate a stable ID based on item characteristics
    static func generateStableID(type: ItemType, text: String, level: Int, indentationLevel: Int, position: Int) -> String {
        // Create a hash of the text content to avoid issues with special characters in IDs
        let textHash = text.data(using: .utf8)?.sha256().hexEncodedString().prefix(8) ?? ""
        
        // Format: "{type}_{indentLevel}_{level}_{textHash}_{position}"
        let generatedID = "\(type.rawValue)_\(indentationLevel)_\(level)_\(textHash)_\(position)"
        print("DEBUG: Generated ID: \(generatedID) [Type: \(type), Indent: \(indentationLevel), Level: \(level), Hash: \(textHash), Position: \(position)]")
        return generatedID
    }
}

// Extension to add SHA256 hashing capability
extension Data {
    func sha256() -> Data {
        return Data(SHA256.hash(data: self))
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}