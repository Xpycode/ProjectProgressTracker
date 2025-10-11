//
//  ContentListView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct ContentListView: View {
    @ObservedObject var document: Document
    @State private var selectedItemID: String?
    
    var body: some View {
        ZStack {
            // Hidden button to capture the spacebar event
            Button("") {
                NotificationCenter.default.post(name: .spacebarPressed, object: nil)
            }
            .keyboardShortcut(.space, modifiers: [])
            .frame(width: 0, height: 0)
            .hidden()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    List(selection: $selectedItemID) {
                        ForEach(visibleItems, id: \.id) { item in
                            switch item.type {
                            case .header:
                                HeaderRowView(document: document, item: item, isSelected: selectedItemID == item.id)
                                    .tag(item.id)
                            case .checkbox:
                                CheckboxRowView(document: document, item: item, isSelected: selectedItemID == item.id)
                                    .tag(item.id)
                            case .text:
                                TextRowView(item: item, isSelected: selectedItemID == item.id)
                                    .tag(item.id)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .spacebarPressed)) { _ in
                        if let selectedItemID = selectedItemID,
                           let item = document.items.first(where: { $0.id == selectedItemID }),
                           item.type == .checkbox {
                            document.updateCheckbox(id: selectedItemID, isChecked: !item.isChecked)
                        }
                    }
                }
                .padding(.horizontal)
            }
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