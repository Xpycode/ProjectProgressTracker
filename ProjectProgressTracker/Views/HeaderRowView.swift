//  HeaderRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct HeaderRowView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var zoom: ZoomManager
    let item: ContentItem
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Button(action: {
                document.toggleHeaderExpansion(headerID: item.id)
            }) {
                Image(systemName: document.isHeaderExpanded(headerID: item.id) ? "chevron.down" : "chevron.right")
                    .font(.caption2) // Smaller chevron
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.text)
                .font(.system(size: 16 * zoom.scale, weight: .semibold)) // adjust base size for each level as needed
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(headerColor)
                .padding(.vertical, 1)
                .padding(.trailing, 2)
            
            Spacer(minLength: 2)
            
            if hasCheckboxes {
                Text(progressText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 0)
                    .background(Color.gray.opacity(0.13))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 1)
        .padding(.leading, CGFloat(item.indentationLevel * 8))
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
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
    HeaderRowView(
        document: Document(),
        item: ContentItem(
            type: .header,
            text: "Main Header",
            level: 1,
            isChecked: false,
            indentationLevel: 0,
            position: 0
        ),
        isSelected: false
    )
}
