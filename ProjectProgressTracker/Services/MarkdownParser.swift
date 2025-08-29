//
//  MarkdownParser.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import RegexBuilder
import CryptoKit

class MarkdownParser {
    static let shared = MarkdownParser()
    
    private init() {}
    
    /// Parses markdown content into structured ContentItems
    func parse(_ content: String) -> [ContentItem] {
        print("DEBUG: Parsing markdown content with \(content.components(separatedBy: .newlines).count) lines")
        let lines = content.components(separatedBy: .newlines)
        var items: [ContentItem] = []
        
        // Track the last header encountered for logical hierarchy
        var lastHeaderLevel: Int? = nil
        
        for (lineIndex, line) in lines.enumerated() {
            // Skip empty lines
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                continue
            }
            
            // Count physical indentation level from original line
            let physicalIndentation = countIndentationLevel(for: line)
            
            // Check for headers (# ## ### etc.)
            if let headerItem = parseHeader(from: trimmedLine, indentationLevel: physicalIndentation, position: items.count) {
                // For headers, use their header level as the logical indentation
                let logicalIndentation = headerItem.level
                let updatedHeaderItem = ContentItem(
                    type: headerItem.type,
                    text: headerItem.text,
                    level: headerItem.level,
                    isChecked: headerItem.isChecked,
                    indentationLevel: logicalIndentation,
                    position: items.count
                )
                
                print("DEBUG: Parsed header item \(items.count): ID=\(updatedHeaderItem.id), Text='\(updatedHeaderItem.text)'")
                items.append(updatedHeaderItem)
                lastHeaderLevel = headerItem.level
                continue
            }
            
            // For non-header items, assign logical indentation based on last header
            let logicalIndentation: Int
            if let headerLevel = lastHeaderLevel {
                // Items after a header get header level + 1 indentation
                logicalIndentation = headerLevel + 1
            } else {
                // Items before any header get level 1 indentation
                logicalIndentation = 1
            }
            
            // Check for checkboxes (- [ ] or - [x])
            if let checkboxItem = parseCheckbox(from: trimmedLine, indentationLevel: logicalIndentation, position: items.count) {
                print("DEBUG: Parsed checkbox item \(items.count): ID=\(checkboxItem.id), Checked=\(checkboxItem.isChecked), Text='\(checkboxItem.text)'")
                items.append(checkboxItem)
                continue
            }
            
            // Treat as regular text
            let textItem = ContentItem(
                type: .text,
                text: trimmedLine,
                indentationLevel: logicalIndentation,
                position: items.count
            )
            print("DEBUG: Parsed text item \(items.count): ID=\(textItem.id), Text='\(textItem.text)'")
            items.append(textItem)
        }
        
        print("DEBUG: Parsing complete, total items: \(items.count)")
        print("DEBUG: Item IDs: \(items.map { $0.id })")
        return items
    }
    
    /// Count leading spaces to determine indentation level
    private func countIndentationLevel(for line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else if char == "\t" {
                count += 4 // Treat tab as 4 spaces
            } else {
                break
            }
        }
        return count
    }
    
    /// Parse header lines (# Header ## Subheader etc.)
    private func parseHeader(from line: String, indentationLevel: Int, position: Int) -> ContentItem? {
        // Headers start with # symbols
        guard line.hasPrefix("#") else { return nil }
        
        var level = 0
        var textStartIndex = line.startIndex
        
        // Count # symbols to determine header level
        for char in line {
            if char == "#" {
                level += 1
                textStartIndex = line.index(textStartIndex, offsetBy: 1)
            } else {
                break
            }
        }
        
        // Limit header levels to 1-6
        level = min(max(level, 1), 6)
        
        // Extract text after # symbols (trimming leading spaces)
        let text = String(line[textStartIndex...]).trimmingCharacters(in: .whitespaces)
        
        let item = ContentItem(
            type: .header,
            text: text,
            level: level,
            isChecked: false, // Headers don't have checkbox state
            indentationLevel: indentationLevel,
            position: position
        )
        
        // print("DEBUG: Created header: ID=\(item.id), Level=\(level), Indent=\(indentationLevel), Pos=\(position)")
        return item
    }
    
    /// Parse checkbox lines (- [ ] or - [x])
    private func parseCheckbox(from line: String, indentationLevel: Int, position: Int) -> ContentItem? {
        // Check for checkbox pattern: - [ ] or - [x] (case insensitive for x)
        let uncheckedPattern = "- [ ]"
        let checkedPattern = "- [x]"
        let checkedPatternUppercase = "- [X]"
        
        var isChecked = false
        var textStartIndex = line.startIndex
        var patternLength = 0
        
        if line.hasPrefix(uncheckedPattern) {
            isChecked = false
            patternLength = uncheckedPattern.count
        } else if line.hasPrefix(checkedPattern) || line.hasPrefix(checkedPatternUppercase) {
            isChecked = true
            patternLength = checkedPattern.count
        } else {
            return nil
        }
        
        // Move index to after the checkbox pattern
        textStartIndex = line.index(line.startIndex, offsetBy: patternLength)
        
        // Extract text after checkbox pattern (trimming leading spaces)
        let text = String(line[textStartIndex...]).trimmingCharacters(in: .whitespaces)
        
        let item = ContentItem(
            type: .checkbox,
            text: text,
            level: 0, // Checkboxes don't have header level
            isChecked: isChecked,
            indentationLevel: indentationLevel,
            position: position
        )
        
        // print("DEBUG: Created checkbox: ID=\(item.id), Checked=\(isChecked), Indent=\(indentationLevel), Pos=\(position)")
        return item
    }
}