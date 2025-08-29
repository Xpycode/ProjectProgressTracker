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
    
    /// Update the checkbox state for a specific item
    func updateCheckbox(id: String, isChecked: Bool) {
        print("DEBUG: === UPDATE CHECKBOX CALLED ===")
        print("DEBUG: Requested ID: \(id), New State: \(isChecked)")
        print("DEBUG: Current items count: \(items.count)")
        print("DEBUG: Current item IDs: \(items.map { $0.id })")
        
        if let index = items.firstIndex(where: { $0.id == id }) {
            print("DEBUG: Found item at index \(index)")
            print("DEBUG: Original item - ID: \(items[index].id), State: \(items[index].isChecked)")
            
            // Create a new ContentItem with updated checked state BUT PRESERVE THE ORIGINAL ID
            let originalItem = items[index]
            print("DEBUG: Creating updated item with preserved ID: \(originalItem.id)")
            let updatedItem = originalItem.withCheckedState(isChecked)
            
            print("DEBUG: ID consistency check - Original: \(originalItem.id), Updated: \(updatedItem.id), Match: \(originalItem.id == updatedItem.id)")
            
            // Replace the item in the array
            items[index] = updatedItem
            
            print("DEBUG: Updated item state to: \(items[index].isChecked)")
            print("DEBUG: Total checkboxes: \(checkboxItems.count), Checked: \(checkedItems.count)")
            print("DEBUG: Completion percentage: \(completionPercentage)%")
            
            // Trigger auto-save with debouncing
            scheduleAutoSave()
        } else {
            print("DEBUG: ERROR - Could not find item with ID: \(id)")
            print("DEBUG: Available IDs: \(items.map { $0.id })")
        }
        print("DEBUG: === UPDATE CHECKBOX FINISHED ===")
    }
    
    /// Toggle header expanded/collapsed state
    func toggleHeaderExpansion(headerID: String) {
        print("DEBUG: Toggling header expansion for ID: \(headerID)")
        print("DEBUG: Current expanded headers: \(expandedHeaders)")
        
        if expandedHeaders.contains(headerID) {
            expandedHeaders.remove(headerID)
            print("DEBUG: Header collapsed, new expanded headers: \(expandedHeaders)")
        } else {
            expandedHeaders.insert(headerID)
            print("DEBUG: Header expanded, new expanded headers: \(expandedHeaders)")
        }
        
        // Trigger auto-save with debouncing
        scheduleAutoSave()
    }
    
    /// Check if a header is expanded
    func isHeaderExpanded(headerID: String) -> Bool {
        let isExpanded = expandedHeaders.contains(headerID)
        // print("DEBUG: Header \(headerID) isExpanded: \(isExpanded)")
        return isExpanded
    }
    
    /// Load items from parsed content
    func loadItems(_ newItems: [ContentItem], filename: String, fileURL: URL) {
        print("DEBUG: === LOADING ITEMS ===")
        print("DEBUG: Loading items for file: \(filename)")
        print("DEBUG: Parsed items count: \(newItems.count)")
        print("DEBUG: Parsed item IDs: \(newItems.map { $0.id })")
        print("DEBUG: Parsed checkboxes with states: \(newItems.filter { $0.type == .checkbox }.map { "\($0.id): \($0.isChecked)" })")
        
        self.markdownFileURL = fileURL
        self.filename = filename
        
        // Try to load saved progress including collapse states
        var itemsWithProgress = newItems
        if let savedData = ProgressPersistence.shared.loadProgress(for: fileURL) {
            print("DEBUG: Found saved data, applying to \(newItems.count) items")
            print("DEBUG: Saved checkbox states count: \(savedData.checkboxStates.count)")
            print("DEBUG: Saved checkbox states with IDs: \(savedData.checkboxStates)")
            
            // Apply checkbox states
            print("DEBUG: Before applying progress - item IDs: \(itemsWithProgress.map { $0.id })")
            ProgressPersistence.shared.applyProgressToItems(&itemsWithProgress, savedStates: savedData.checkboxStates)
            print("DEBUG: After applying progress - item IDs: \(itemsWithProgress.map { $0.id })")
            print("DEBUG: After applying progress - checkbox states: \(itemsWithProgress.filter { $0.type == .checkbox }.map { "\($0.id): \($0.isChecked)" })")
            
            // Apply collapse states - now using String IDs directly
            expandedHeaders = savedData.expandedHeaders
            print("DEBUG: Applied expanded headers: \(expandedHeaders)")
        } else {
            print("DEBUG: No saved data found, using defaults")
            // Default to all headers expanded
            let headerIDs = newItems.filter { $0.type == .header }.map { $0.id }
            expandedHeaders = Set(headerIDs)
            print("DEBUG: Default expanded headers: \(expandedHeaders)")
        }
        
        self.items = itemsWithProgress
        print("DEBUG: Final items count: \(items.count)")
        print("DEBUG: Final checkboxes with states: \(items.filter { $0.type == .checkbox }.map { "\($0.id): \($0.isChecked)" })")
        print("DEBUG: Final checkbox count: \(checkboxItems.count)")
        print("DEBUG: Final checked count: \(checkedItems.count)")
        print("DEBUG: Final completion: \(completionPercentage)%")
        print("DEBUG: === FINISHED LOADING ITEMS ===")
    }
    
    /// Schedule auto-save with debouncing
    private func scheduleAutoSave() {
        print("DEBUG: Scheduling auto-save")
        // Cancel any existing save operation
        saveCancellable?.cancel()
        
        // Schedule new save operation
        saveCancellable = Just(())
            .delay(for: .seconds(saveDebounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.saveProgress()
            }
    }
    
    /// Save progress immediately
    private func saveProgress() {
        print("DEBUG: === SAVING PROGRESS ===")
        print("DEBUG: Current items count: \(items.count)")
        print("DEBUG: Current checkboxes with states: \(items.filter { $0.type == .checkbox }.map { "\($0.id): \($0.isChecked)" })")
        
        guard let fileURL = markdownFileURL else { 
            print("DEBUG: No file URL, skipping save")
            return 
        }
        
        isSaving = true
        let success = ProgressPersistence.shared.saveProgress(for: self, markdownFileURL: fileURL)
        isSaving = false
        
        if success {
            lastSaveTime = Date()
            print("DEBUG: Progress saved successfully at \(lastSaveTime ?? Date())")
        } else {
            print("DEBUG: Failed to save progress")
        }
        print("DEBUG: === FINISHED SAVING PROGRESS ===")
    }
    
    /// Get all checkbox items
    var checkboxItems: [ContentItem] {
        let checkboxes = items.filter { $0.type == .checkbox }
        // print("DEBUG: Found \(checkboxes.count) checkbox items")
        return checkboxes
    }
    
    /// Get checked checkbox items
    var checkedItems: [ContentItem] {
        let checked = items.filter { $0.type == .checkbox && $0.isChecked }
        // print("DEBUG: Found \(checked.count) checked items")
        return checked
    }
    
    /// Get unchecked checkbox items
    var uncheckedItems: [ContentItem] {
        let unchecked = items.filter { $0.type == .checkbox && !$0.isChecked }
        // print("DEBUG: Found \(unchecked.count) unchecked items")
        return unchecked
    }
    
    /// Calculate completion percentage
    var completionPercentage: Double {
        let totalCheckboxes = checkboxItems.count
        guard totalCheckboxes > 0 else { 
            print("DEBUG: No checkboxes found, completion: 0%")
            return 0 
        }
        
        let checkedCount = checkedItems.count
        let percentage = Double(checkedCount) / Double(totalCheckboxes) * 100
        // print("DEBUG: Completion calculation - Checked: \(checkedCount)/\(totalCheckboxes) = \(percentage)%")
        return percentage
    }
    
    /// Get checkbox statistics for a specific header section
    /// Returns (totalCheckboxes, checkedCheckboxes) for items under the given header
    func checkboxStats(for headerItem: ContentItem) -> (total: Int, checked: Int) {
        guard headerItem.type == .header else { 
            print("DEBUG: Item is not a header, returning (0,0)")
            return (0, 0) 
        }
        
        var totalCheckboxes = 0
        var checkedCheckboxes = 0
        var foundHeader = false
        var headerIndex = -1
        
        // Find the header in our items
        for (index, item) in items.enumerated() {
            if item.id == headerItem.id {
                foundHeader = true
                headerIndex = index
                break
            }
        }
        
        // If we didn't find the header, return zeros
        guard foundHeader, headerIndex >= 0 else { 
            print("DEBUG: Header not found, returning (0,0)")
            return (0, 0) 
        }
        
        print("DEBUG: Found header at index \(headerIndex), level \(headerItem.indentationLevel)")
        
        // Start from the next item after the header
        for index in (headerIndex + 1)..<items.count {
            let item = items[index]
            
            // Stop if we encounter a header at the same or lower indentation level
            // This means we've moved to a sibling or parent header
            if item.type == .header && item.indentationLevel <= headerItem.indentationLevel {
                print("DEBUG: Stopping at header with level \(item.indentationLevel) (<= \(headerItem.indentationLevel))")
                break
            }
            
            // Count checkboxes that are direct children or grandchildren of this header
            if item.type == .checkbox && item.indentationLevel > headerItem.indentationLevel {
                totalCheckboxes += 1
                if item.isChecked {
                    checkedCheckboxes += 1
                }
            }
        }
        
        print("DEBUG: Header stats - Total: \(totalCheckboxes), Checked: \(checkedCheckboxes)")
        return (totalCheckboxes, checkedCheckboxes)
    }
    
    /// File URL for this document
    var fileURL: URL? {
        return markdownFileURL
    }
}