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
        var result: [ContentItem] = []
        var isHidden = false
        var hiddenUntilLevel = -1

        for item in document.items {
            if item.type == .header {
                if isHidden && item.level <= hiddenUntilLevel {
                    isHidden = false
                    hiddenUntilLevel = -1
                }
                
                if !isHidden {
                    result.append(item)
                    if !document.isHeaderExpanded(headerID: item.id) {
                        isHidden = true
                        hiddenUntilLevel = item.level
                    }
                }
            } else {
                if !isHidden {
                    result.append(item)
                }
            }
        }
        return result
    }
}

#Preview {
    let document = Document()
    return ContentListView(document: document)
}