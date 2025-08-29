//
//  HeaderRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct HeaderRowView: View {
    @ObservedObject var document: Document
    let item: ContentItem
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // Collapse/expand button for header items
            Button(action: {
                document.toggleHeaderExpansion(headerID: item.id)
            }) {
                Image(systemName: document.isHeaderExpanded(headerID: item.id) ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .font(headerFont)
                .fontWeight(.semibold)
                .foregroundColor(headerColor)
            
            // Progress counter for headers with checkboxes
            if hasCheckboxes {
                Text(progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
        .padding(.leading, CGFloat(item.indentationLevel * 10))
        .contentShape(Rectangle()) // Make the entire area tappable
        .onTapGesture {
            document.toggleHeaderExpansion(headerID: item.id)
        }
    }
    
    private var headerFont: Font {
        switch item.level {
        case 1:
            return .title
        case 2:
            return .title2
        case 3:
            return .title3
        case 4:
            return .headline
        case 5:
            return .body
        case 6:
            return .callout
        default:
            return .body
        }
    }
    
    private var headerColor: Color {
        switch item.level {
        case 1:
            return .primary
        case 2:
            return .primary
        case 3:
            return .primary
        default:
            return .secondary
        }
    }
    
    // Check if this header has any checkboxes underneath it
    private var hasCheckboxes: Bool {
        let stats = document.checkboxStats(for: item)
        return stats.total > 0
    }
    
    // Get the progress text for display
    private var progressText: String {
        let stats = document.checkboxStats(for: item)
        return "\(stats.checked)/\(stats.total)"
    }
}

#Preview {
    let document = Document()
    let item = ContentItem(
        type: .header,
        text: "Main Header",
        level: 1,
        isChecked: false,
        indentationLevel: 0,
        position: 0
    )
    return HeaderRowView(document: document, item: item)
}