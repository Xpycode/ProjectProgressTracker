//
//  ContentListView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI
import AppKit

struct ContentListView: View {
    @ObservedObject var document: Document
    @Binding var searchText: String
    @Binding var filterState: FilterState
    @State private var selectedItemIDs: Set<String> = []

    var body: some View {
        ZStack {
            // Hidden button to capture the spacebar event
            Button("") {
                NotificationCenter.default.post(name: .spacebarPressed, object: nil)
            }
            .keyboardShortcut(.space, modifiers: [])
            .frame(width: 0, height: 0)
            .hidden()

            // Hidden button to capture copy command (Cmd+C)
            Button("") {
                copySelectedItem()
            }
            .keyboardShortcut("c", modifiers: .command)
            .frame(width: 0, height: 0)
            .hidden()

            ScrollViewReader { proxy in
                List(selection: $selectedItemIDs) {
                    ForEach(filteredItems, id: \.id) { item in
                        switch item.type {
                        case .header:
                            HeaderRowView(document: document, item: item, isSelected: selectedItemIDs.contains(item.id))
                                .tag(item.id)
                                .padding(.horizontal)
                                .id(item.id)
                        case .checkbox:
                            CheckboxRowView(document: document, item: item, isSelected: selectedItemIDs.contains(item.id))
                                .tag(item.id)
                                .padding(.horizontal)
                                .id(item.id)
                        case .text:
                            TextRowView(item: item, isSelected: selectedItemIDs.contains(item.id))
                                .tag(item.id)
                                .padding(.horizontal)
                                .id(item.id)
                        }
                    }
                }
                .listStyle(.plain)
                .onReceive(NotificationCenter.default.publisher(for: .spacebarPressed)) { _ in
                    toggleSelectedCheckboxes()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToNextHeader)) { _ in
                    navigateToNextHeader()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPreviousHeader)) { _ in
                    navigateToPreviousHeader()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToNextSubHeader)) { _ in
                    navigateToNextSubHeader()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPreviousSubHeader)) { _ in
                    navigateToPreviousSubHeader()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToNextBoldCheckbox)) { _ in
                    navigateToNextBoldCheckbox()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPreviousBoldCheckbox)) { _ in
                    navigateToPreviousBoldCheckbox()
                }
                .onChange(of: selectedItemIDs) { _, newSelection in
                    if let firstID = newSelection.first {
                        withAnimation {
                            proxy.scrollTo(firstID, anchor: .center)
                        }
                    }
                }
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

    private var filteredItems: [ContentItem] {
        let visible = visibleItems

        // Apply text search
        let searchedItems = if searchText.isEmpty {
            visible
        } else {
            visible.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply state filter
        switch filterState {
        case .all:
            return searchedItems
        case .unchecked:
            return searchedItems.filter { $0.type != .checkbox || !$0.isChecked }
        case .checked:
            return searchedItems.filter { $0.type != .checkbox || $0.isChecked }
        }
    }

    private func toggleSelectedCheckboxes() {
        // Filter selected items to only checkboxes
        let checkboxIDs = selectedItemIDs.filter { id in
            guard let item = document.items.first(where: { $0.id == id }) else { return false }
            return item.type == .checkbox
        }

        guard !checkboxIDs.isEmpty else { return }

        // Determine if we should check or uncheck based on the first selected checkbox
        if let firstCheckboxID = checkboxIDs.first,
           let firstCheckbox = document.items.first(where: { $0.id == firstCheckboxID }) {
            let newState = !firstCheckbox.isChecked

            // Toggle all selected checkboxes to the same state
            for checkboxID in checkboxIDs {
                document.updateCheckbox(id: checkboxID, isChecked: newState)
            }
        }
    }

    private func navigateToNextHeader() {
        // Navigate to main section headers (skip the document title, use level 2 or the most common level)
        let allHeaders = filteredItems.filter { $0.type == .header }
        guard !allHeaders.isEmpty else { return }

        // Find the level to navigate: prefer level 2, or if not available, use the most common level
        let targetLevel: Int
        let level2Headers = allHeaders.filter { $0.level == 2 }
        if !level2Headers.isEmpty {
            targetLevel = 2
        } else {
            // Find the most common header level
            let levelCounts = Dictionary(grouping: allHeaders, by: { $0.level }).mapValues { $0.count }
            targetLevel = levelCounts.max(by: { $0.value < $1.value })?.key ?? 1
        }

        let topHeaders = allHeaders.filter { $0.level == targetLevel }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the next top-level header after the current position
            for i in (currentIndex + 1)..<filteredItems.count {
                if filteredItems[i].type == .header && filteredItems[i].level == targetLevel {
                    selectedItemIDs = [filteredItems[i].id]
                    return
                }
            }

            // If no header found after, wrap to the first header
            if let firstHeader = topHeaders.first {
                selectedItemIDs = [firstHeader.id]
            }
        } else {
            // No selection, select the first header
            if let firstHeader = topHeaders.first {
                selectedItemIDs = [firstHeader.id]
            }
        }
    }

    private func navigateToPreviousHeader() {
        // Navigate to main section headers (skip the document title, use level 2 or the most common level)
        let allHeaders = filteredItems.filter { $0.type == .header }
        guard !allHeaders.isEmpty else { return }

        // Find the level to navigate: prefer level 2, or if not available, use the most common level
        let targetLevel: Int
        let level2Headers = allHeaders.filter { $0.level == 2 }
        if !level2Headers.isEmpty {
            targetLevel = 2
        } else {
            // Find the most common header level
            let levelCounts = Dictionary(grouping: allHeaders, by: { $0.level }).mapValues { $0.count }
            targetLevel = levelCounts.max(by: { $0.value < $1.value })?.key ?? 1
        }

        let topHeaders = allHeaders.filter { $0.level == targetLevel }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the previous top-level header before the current position
            for i in (0..<currentIndex).reversed() {
                if filteredItems[i].type == .header && filteredItems[i].level == targetLevel {
                    selectedItemIDs = [filteredItems[i].id]
                    return
                }
            }

            // If no header found before, wrap to the last header
            if let lastHeader = topHeaders.last {
                selectedItemIDs = [lastHeader.id]
            }
        } else {
            // No selection, select the last header
            if let lastHeader = topHeaders.last {
                selectedItemIDs = [lastHeader.id]
            }
        }
    }

    private func navigateToNextSubHeader() {
        // Navigate to all headers (any level)
        let allHeaders = filteredItems.filter { $0.type == .header }
        guard !allHeaders.isEmpty else { return }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the next header after the current position
            for i in (currentIndex + 1)..<filteredItems.count {
                if filteredItems[i].type == .header {
                    selectedItemIDs = [filteredItems[i].id]
                    return
                }
            }

            // If no header found after, wrap to the first header
            if let firstHeader = allHeaders.first {
                selectedItemIDs = [firstHeader.id]
            }
        } else {
            // No selection, select the first header
            if let firstHeader = allHeaders.first {
                selectedItemIDs = [firstHeader.id]
            }
        }
    }

    private func navigateToPreviousSubHeader() {
        // Navigate to all headers (any level)
        let allHeaders = filteredItems.filter { $0.type == .header }
        guard !allHeaders.isEmpty else { return }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the previous header before the current position
            for i in (0..<currentIndex).reversed() {
                if filteredItems[i].type == .header {
                    selectedItemIDs = [filteredItems[i].id]
                    return
                }
            }

            // If no header found before, wrap to the last header
            if let lastHeader = allHeaders.last {
                selectedItemIDs = [lastHeader.id]
            }
        } else {
            // No selection, select the last header
            if let lastHeader = allHeaders.last {
                selectedItemIDs = [lastHeader.id]
            }
        }
    }

    private func navigateToNextBoldCheckbox() {
        // Navigate to "parent" checkboxes: either bold text or checkboxes with children
        let parentCheckboxes = filteredItems.enumerated().compactMap { index, item -> ContentItem? in
            guard item.type == .checkbox else { return nil }

            // Check if it's bold
            if item.text.hasPrefix("**") {
                return item
            }

            // Check if it has children (next item has higher indentation)
            if index + 1 < filteredItems.count {
                let nextItem = filteredItems[index + 1]
                if nextItem.indentationLevel > item.indentationLevel {
                    return item
                }
            }

            return nil
        }
        guard !parentCheckboxes.isEmpty else { return }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the next parent checkbox after the current position
            for i in (currentIndex + 1)..<filteredItems.count {
                if let found = parentCheckboxes.first(where: { $0.id == filteredItems[i].id }) {
                    selectedItemIDs = [found.id]
                    return
                }
            }

            // If no parent checkbox found after, wrap to the first one
            if let firstParent = parentCheckboxes.first {
                selectedItemIDs = [firstParent.id]
            }
        } else {
            // No selection, select the first parent checkbox
            if let firstParent = parentCheckboxes.first {
                selectedItemIDs = [firstParent.id]
            }
        }
    }

    private func navigateToPreviousBoldCheckbox() {
        // Navigate to "parent" checkboxes: either bold text or checkboxes with children
        let parentCheckboxes = filteredItems.enumerated().compactMap { index, item -> ContentItem? in
            guard item.type == .checkbox else { return nil }

            // Check if it's bold
            if item.text.hasPrefix("**") {
                return item
            }

            // Check if it has children (next item has higher indentation)
            if index + 1 < filteredItems.count {
                let nextItem = filteredItems[index + 1]
                if nextItem.indentationLevel > item.indentationLevel {
                    return item
                }
            }

            return nil
        }
        guard !parentCheckboxes.isEmpty else { return }

        // Find the currently selected item
        if let currentID = selectedItemIDs.first,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) {

            // Find the previous parent checkbox before the current position
            for i in (0..<currentIndex).reversed() {
                if let found = parentCheckboxes.first(where: { $0.id == filteredItems[i].id }) {
                    selectedItemIDs = [found.id]
                    return
                }
            }

            // If no parent checkbox found before, wrap to the last one
            if let lastParent = parentCheckboxes.last {
                selectedItemIDs = [lastParent.id]
            }
        } else {
            // No selection, select the last parent checkbox
            if let lastParent = parentCheckboxes.last {
                selectedItemIDs = [lastParent.id]
            }
        }
    }

    private func copySelectedItem() {
        guard let selectedItemID = selectedItemIDs.first,
              let item = document.items.first(where: { $0.id == selectedItemID }) else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
    }
}

#Preview {
    let document = Document()
    return ContentListView(document: document, searchText: .constant(""), filterState: .constant(.all))
}