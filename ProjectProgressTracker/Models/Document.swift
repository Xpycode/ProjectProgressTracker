//
//  Document.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import Combine

class Document: ObservableObject, Identifiable {
    let id = UUID()
    @Published var items: [ContentItem] = []
    @Published var filename: String = ""
    @Published var isSaving: Bool = false
    @Published var lastSaveTime: Date?
    
    // Track expanded/collapsed state for headers (now using String IDs)
    @Published var expandedHeaders: Set<String> = []
    
    private var markdownFileURL: URL?
    private var saveCancellable: AnyCancellable?
    private let saveDebounceInterval: TimeInterval = 1.0 // 1 second debounce
    
    /// Update the checkbox state for a specific item with cascading behavior
    func updateCheckbox(id: String, isChecked: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard items[index].type == .checkbox else { return }

        let parentIndentation = items[index].indentationLevel

        // Update the checkbox itself
        items[index] = items[index].withCheckedState(isChecked)

        // Cascade down: Check/uncheck all child checkboxes
        updateChildCheckboxes(startingAt: index, parentIndentation: parentIndentation, isChecked: isChecked)

        // Cascade up: Auto-check parent if all siblings are checked
        if isChecked {
            updateParentCheckboxes(childIndex: index)
        }

        scheduleAutoSave()
    }

    /// Update all child checkboxes (items with higher indentation level)
    private func updateChildCheckboxes(startingAt parentIndex: Int, parentIndentation: Int, isChecked: Bool) {
        // Iterate through items after the parent
        for i in (parentIndex + 1)..<items.count {
            let currentItem = items[i]

            // Stop when we hit an item at the same or lower indentation level
            if currentItem.indentationLevel <= parentIndentation {
                break
            }

            // Update child checkboxes
            if currentItem.type == .checkbox {
                items[i] = currentItem.withCheckedState(isChecked)
            }
        }
    }

    /// Check if parent checkbox should be auto-checked when all children are checked
    private func updateParentCheckboxes(childIndex: Int) {
        let childIndentation = items[childIndex].indentationLevel

        // Find the parent checkbox (first checkbox with lower indentation above this one)
        var parentIndex: Int?
        for i in (0..<childIndex).reversed() {
            let item = items[i]
            if item.type == .checkbox && item.indentationLevel < childIndentation {
                parentIndex = i
                break
            }
        }

        guard let parentIdx = parentIndex else { return }

        let parentIndentation = items[parentIdx].indentationLevel

        // Check if all sibling checkboxes (same indentation) are checked
        var allSiblingsChecked = true
        for i in (parentIdx + 1)..<items.count {
            let item = items[i]

            // Stop when we exit the parent's scope
            if item.indentationLevel <= parentIndentation {
                break
            }

            // Only check direct children (one level deeper)
            if item.type == .checkbox && item.indentationLevel == childIndentation {
                if !item.isChecked {
                    allSiblingsChecked = false
                    break
                }
            }
        }

        // If all siblings are checked, check the parent and recurse upward
        if allSiblingsChecked && !items[parentIdx].isChecked {
            items[parentIdx] = items[parentIdx].withCheckedState(true)
            updateParentCheckboxes(childIndex: parentIdx)
        }
    }
    
    /// Toggle header expanded/collapsed state
    func toggleHeaderExpansion(headerID: String) {
        if expandedHeaders.contains(headerID) {
            expandedHeaders.remove(headerID)
        } else {
            expandedHeaders.insert(headerID)
        }
    }
    
    /// Check if a header is expanded
    func isHeaderExpanded(headerID: String) -> Bool {
        return expandedHeaders.contains(headerID)
    }
    
    /// Load items from parsed content
    func loadItems(_ newItems: [ContentItem], filename: String, fileURL: URL) {
        self.markdownFileURL = fileURL
        self.filename = filename
        
        var itemsWithProgress = newItems
        if let savedData = ProgressPersistence.shared.loadProgress(for: fileURL) {
            ProgressPersistence.shared.applyProgressToItems(&itemsWithProgress, savedStates: savedData.checkboxStates)
            expandedHeaders = savedData.expandedHeaders
        } else {
            let headerIDs = newItems.filter { $0.type == .header }.map { $0.id }
            expandedHeaders = Set(headerIDs)
        }
        
        self.items = itemsWithProgress
    }
    
    /// Schedule auto-save with debouncing
    private func scheduleAutoSave() {
        saveCancellable?.cancel()
        
        saveCancellable = Just(())
            .delay(for: .seconds(saveDebounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.saveProgress()
            }
    }
    
    /// Save progress immediately
    private func saveProgress() {
        guard let fileURL = markdownFileURL else { 
            return 
        }
        
        isSaving = true
        let success = ProgressPersistence.shared.saveProgress(for: self, markdownFileURL: fileURL)
        isSaving = false
        
        if success {
            lastSaveTime = Date()
        }
    }
    
    /// Get all checkbox items
    var checkboxItems: [ContentItem] {
        return items.filter { $0.type == .checkbox }
    }
    
    /// Get checked checkbox items
    var checkedItems: [ContentItem] {
        return items.filter { $0.type == .checkbox && $0.isChecked }
    }
    
    /// Get unchecked checkbox items
    var uncheckedItems: [ContentItem] {
        return items.filter { $0.type == .checkbox && !$0.isChecked }
    }
    
    /// Calculate completion percentage
    var completionPercentage: Double {
        let totalCheckboxes = checkboxItems.count
        guard totalCheckboxes > 0 else { 
            return 0 
        }
        
        let checkedCount = checkedItems.count
        return Double(checkedCount) / Double(totalCheckboxes) * 100
    }
    
    /// Get checkbox statistics for a specific header section
    /// Returns (totalCheckboxes, checkedCheckboxes) for items under the given header
    func checkboxStats(for headerItem: ContentItem) -> (total: Int, checked: Int) {
        guard headerItem.type == .header else {
            return (0, 0)
        }

        var totalCheckboxes = 0
        var checkedCheckboxes = 0

        guard let headerIndex = items.firstIndex(where: { $0.id == headerItem.id }) else {
            return (0, 0)
        }

        // Iterate through items following the header
        for i in (headerIndex + 1)..<items.count {
            let currentItem = items[i]

            // If we encounter another header of the same or higher level, stop counting.
            if currentItem.type == .header && currentItem.level <= headerItem.level {
                break
            }

            // Count checkboxes that are children of this header
            if currentItem.type == .checkbox {
                totalCheckboxes += 1
                if currentItem.isChecked {
                    checkedCheckboxes += 1
                }
            }
        }

        return (totalCheckboxes, checkedCheckboxes)
    }

    /// Get child checkbox statistics for a parent checkbox
    /// Returns (totalCheckboxes, checkedCheckboxes) for child checkboxes
    func childCheckboxStats(for checkboxItem: ContentItem) -> (total: Int, checked: Int) {
        guard checkboxItem.type == .checkbox else {
            return (0, 0)
        }

        var totalCheckboxes = 0
        var checkedCheckboxes = 0

        guard let checkboxIndex = items.firstIndex(where: { $0.id == checkboxItem.id }) else {
            return (0, 0)
        }

        let parentIndentation = checkboxItem.indentationLevel

        // Iterate through items following the checkbox
        for i in (checkboxIndex + 1)..<items.count {
            let currentItem = items[i]

            // Stop when we hit an item at the same or lower indentation level
            if currentItem.indentationLevel <= parentIndentation {
                break
            }

            // Count child checkboxes
            if currentItem.type == .checkbox {
                totalCheckboxes += 1
                if currentItem.isChecked {
                    checkedCheckboxes += 1
                }
            }
        }

        return (totalCheckboxes, checkedCheckboxes)
    }
    
    /// File URL for this document
    var fileURL: URL? {
        return markdownFileURL
    }

    func items(numberOfNextItems: Int) -> (ContentItem?, [ContentItem]) {
        let lastChecked = checkedItems.last
        let upcomingItems = uncheckedItems
        
        if upcomingItems.isEmpty {
            return (lastChecked, [])
        }
        
        // Find the index of the first upcoming item in the main items array
        guard let firstUpcomingIndex = items.firstIndex(where: { $0.id == upcomingItems.first?.id }) else {
            return (lastChecked, Array(upcomingItems.prefix(numberOfNextItems)))
        }
        
        // Find the header that precedes this item
        let header = items[0..<firstUpcomingIndex]
            .last { $0.type == .header }
            
        var results: [ContentItem] = []
        if let header = header {
            results.append(header)
        }
        results.append(contentsOf: upcomingItems.prefix(numberOfNextItems))
        
        return (lastChecked, results)
    }
}