//
//  MarkdownParser.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import RegexBuilder
import CryptoKit
import AppKit

class MarkdownParser {
    static let shared = MarkdownParser()

    private init() {}

    /// Detects if content is RTF and converts it to plain text if needed
    private func preprocessContent(_ content: String) -> String {
        // Check if content starts with RTF header
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{\\rtf") else {
            return content
        }

        // Convert RTF to plain text using NSAttributedString
        guard let data = content.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            // If RTF conversion fails, return original content
            return content
        }

        return attributedString.string
    }

    /// Parses markdown content into structured ContentItems
    func parse(_ content: String) -> [ContentItem] {
        // Preprocess to handle RTF files saved with .md extension
        let processedContent = preprocessContent(content)
        let lines = processedContent.components(separatedBy: .newlines)
        var items: [ContentItem] = []
        
        for (_, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                continue
            }
            
            let indentationLevel = countIndentationLevel(for: line)
            let position = items.count
            
            if let headerItem = parseHeader(from: trimmedLine, indentationLevel: indentationLevel, position: position) {
                items.append(headerItem)
            } else if let checkboxItem = parseCheckbox(from: trimmedLine, indentationLevel: indentationLevel, position: position) {
                items.append(checkboxItem)
            } else {
                let textItem = ContentItem(
                    type: .text,
                    text: trimmedLine,
                    indentationLevel: indentationLevel,
                    position: position
                )
                items.append(textItem)
            }
        }
        
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
        var text = String(line[textStartIndex...]).trimmingCharacters(in: .whitespaces)
        var dueDate: Date?

        // Regex to find "due:YYYY-MM-DD"
        let regex = #/due:(\d{4}-\d{2}-\d{2})/#
        if let match = text.firstMatch(of: regex) {
            let dateString = String(match.1)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                dueDate = date
                // Remove the due date string from the text
                text = text.replacing(regex, with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        let item = ContentItem(
            type: .checkbox,
            text: text,
            level: 0, // Checkboxes don't have header level
            isChecked: isChecked,
            indentationLevel: indentationLevel,
            position: position,
            dueDate: dueDate
        )
        
        // print("DEBUG: Created checkbox: ID=\(item.id), Checked=\(isChecked), Indent=\(indentationLevel), Pos=\(position)")
        return item
    }

    /// Reconstructs a markdown string from an array of ContentItems
    func reconstruct(from items: [ContentItem]) -> String {
        var lines: [String] = []
        for item in items {
            let indentation = String(repeating: " ", count: item.indentationLevel)
            var line = ""
            switch item.type {
            case .header:
                let headerPrefix = String(repeating: "#", count: item.level)
                line = "\(indentation)\(headerPrefix) \(item.text)"
            case .checkbox:
                let checkboxState = item.isChecked ? "[x]" : "[ ]"
                var text = item.text
                if let dueDate = item.dueDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    text += " due:\(formatter.string(from: dueDate))"
                }
                line = "\(indentation)- \(checkboxState) \(text)"
            case .text:
                line = "\(indentation)\(item.text)"
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}