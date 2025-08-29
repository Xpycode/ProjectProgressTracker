//
//  ContentListView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct ContentListView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(visibleItems, id: \.id) { item in
                    switch item.type {
                    case .header:
                        HeaderRowView(document: document, item: item)
                    case .checkbox:
                        CheckboxRowView(document: document, item: item)
                    case .text:
                        TextRowView(item: item)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // Computed property that filters items based on header collapse states
    private var visibleItems: [ContentItem] {
        var visible: [ContentItem] = []
        var collapsedDepths: [Int] = [] // Track indentation levels where content is collapsed
        
        for item in document.items {
            // Remove collapsed depths that are no longer relevant
            // When moving to a new item, clear any collapse states from equal or deeper levels
            // This ensures proper hierarchy management when moving between branches
            collapsedDepths.removeAll { $0 >= item.indentationLevel }
            
            // Check if this item should be hidden due to any collapsed ancestor
            let shouldBeHidden = collapsedDepths.contains { collapsedDepth in
                item.indentationLevel > collapsedDepth
            }
            
            if item.type == .header {
                // Headers are visible if not hidden by ancestors
                // (But their content may still be hidden if the header itself is collapsed)
                if !shouldBeHidden {
                    visible.append(item)
                    
                    // If this header itself is collapsed, add its level to hide its children
                    if !document.isHeaderExpanded(headerID: item.id) {
                        collapsedDepths.append(item.indentationLevel)
                    }
                }
            } else {
                // Content items are only visible if not hidden by collapsed ancestors
                if !shouldBeHidden {
                    visible.append(item)
                }
            }
        }
        
        return visible
    }
}

#Preview {
    let document = Document()
    return ContentListView(document: document)
}