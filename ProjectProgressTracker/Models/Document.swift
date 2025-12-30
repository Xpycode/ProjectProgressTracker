//
//  Document.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import Combine

/// Represents a single undo action for checkbox state changes
struct CheckboxUndoAction {
    let changes: [(id: String, wasChecked: Bool)]
    let previousLastCheckedItemID: String?
}

class Document: ObservableObject, Identifiable {
    let id = UUID()
    @Published var items: [ContentItem] = []
    @Published var filename: String = ""
    @Published var isSaving: Bool = false
    @Published var lastSaveTime: Date?
    @Published var lastAccessedDate: Date
    @Published var lastCheckedDate: Date?
    @Published var fileModificationDate: Date?
    @Published var hasUnsavedChanges: Bool = false
    @Published var reloadError: String?

    // Track the most recently checked item (for "Last Completed" display)
    @Published var lastCheckedItemID: String?

    // Track expanded/collapsed state for headers (now using String IDs)
    @Published var expandedHeaders: Set<String> = []

    // Undo/Redo stacks
    private var undoStack: [CheckboxUndoAction] = []
    private var redoStack: [CheckboxUndoAction] = []
    private let maxUndoSteps = 10

    private var fileWatcher: FileWatcher?
    private var markdownFileURL: URL?
    private var saveCancellable: AnyCancellable?
    private let saveDebounceInterval: TimeInterval = 1.0 // 1 second debounce
    private var isAccessingSecurityScopedResource: Bool = false

    init() {
        self.lastAccessedDate = Date()
    }

    deinit {
        stopAccessingSecurityScopedResource()
        fileWatcher?.stop()
    }

    private func startFileWatcher() {
        guard let url = markdownFileURL else { return }
        fileWatcher = FileWatcher(fileURL: url) { [weak self] in
            self?.hasUnsavedChanges = true
        }
        fileWatcher?.start()
    }

    func reload() {
        guard let url = markdownFileURL else {
            reloadError = "No file URL available"
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let newItems = MarkdownParser.shared.parse(content)

            // Load saved progress and reconcile with new items
            let savedProgress = ProgressPersistence.shared.loadProgress(for: url)
            let (reconciledItems, reconciledHeaders) = ProgressPersistence.shared.reconcile(
                newItems: newItems,
                with: savedProgress
            )

            self.items = reconciledItems
            self.expandedHeaders = reconciledHeaders
            self.hasUnsavedChanges = false
            self.reloadError = nil

            // Update file modification date
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                self.fileModificationDate = modificationDate
            }
        } catch {
            reloadError = "Failed to reload file: \(error.localizedDescription)"
            print("Error reloading file: \(error)")
        }
    }

    /// Start accessing a security-scoped resource
    func startAccessingSecurityScopedResource() {
        guard let url = markdownFileURL, !isAccessingSecurityScopedResource else { return }
        if url.startAccessingSecurityScopedResource() {
            isAccessingSecurityScopedResource = true
        }
    }

    /// Stop accessing the security-scoped resource
    func stopAccessingSecurityScopedResource() {
        guard let url = markdownFileURL, isAccessingSecurityScopedResource else { return }
        url.stopAccessingSecurityScopedResource()
        isAccessingSecurityScopedResource = false
    }

    /// Update the checkbox state for a specific item with cascading behavior
    func updateCheckbox(id: String, isChecked: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard items[index].type == .checkbox else { return }

        // Record state before changes for undo
        let previousLastCheckedID = lastCheckedItemID
        var changedItems: [(id: String, wasChecked: Bool)] = []

        let parentIndentation = items[index].indentationLevel

        // Record the main checkbox state
        changedItems.append((id: id, wasChecked: items[index].isChecked))

        // Update the checkbox itself
        items[index] = items[index].withCheckedState(isChecked)

        // Cascade down: Check/uncheck all child checkboxes (and record changes)
        for i in (index + 1)..<items.count {
            let currentItem = items[i]
            if currentItem.indentationLevel <= parentIndentation {
                break
            }
            if currentItem.type == .checkbox && currentItem.isChecked != isChecked {
                changedItems.append((id: currentItem.id, wasChecked: currentItem.isChecked))
                items[i] = currentItem.withCheckedState(isChecked)
            }
        }

        // Cascade up: Auto-check parent if all siblings are checked
        if isChecked {
            recordAndUpdateParentCheckboxes(childIndex: index, changedItems: &changedItems)
            // Track this as the most recently checked item
            lastCheckedItemID = id
        }

        // Push to undo stack
        let undoAction = CheckboxUndoAction(changes: changedItems, previousLastCheckedItemID: previousLastCheckedID)
        undoStack.append(undoAction)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        // Clear redo stack when a new action is performed
        redoStack.removeAll()

        // Update last checked date
        lastCheckedDate = Date()

        scheduleAutoSave()

        // Also save progress to local file
        if let url = markdownFileURL {
            _ = ProgressPersistence.shared.saveProgress(for: self, markdownFileURL: url)
        }
    }

    /// Record parent checkbox changes and update them (for undo tracking)
    private func recordAndUpdateParentCheckboxes(childIndex: Int, changedItems: inout [(id: String, wasChecked: Bool)]) {
        let childIndentation = items[childIndex].indentationLevel

        // Find the parent checkbox
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

        // Check if all sibling checkboxes are checked
        var allSiblingsChecked = true
        for i in (parentIdx + 1)..<items.count {
            let item = items[i]
            if item.indentationLevel <= parentIndentation {
                break
            }
            if item.type == .checkbox && item.indentationLevel == childIndentation {
                if !item.isChecked {
                    allSiblingsChecked = false
                    break
                }
            }
        }

        // If all siblings are checked, check the parent and recurse upward
        if allSiblingsChecked && !items[parentIdx].isChecked {
            changedItems.append((id: items[parentIdx].id, wasChecked: items[parentIdx].isChecked))
            items[parentIdx] = items[parentIdx].withCheckedState(true)
            recordAndUpdateParentCheckboxes(childIndex: parentIdx, changedItems: &changedItems)
        }
    }

    // MARK: - Undo/Redo

    /// Whether undo is available
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// Whether redo is available
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// Undo the last checkbox action
    func undo() {
        guard let action = undoStack.popLast() else { return }

        // Record current state for redo
        var redoChanges: [(id: String, wasChecked: Bool)] = []
        for change in action.changes {
            if let index = items.firstIndex(where: { $0.id == change.id }) {
                redoChanges.append((id: change.id, wasChecked: items[index].isChecked))
            }
        }
        let redoAction = CheckboxUndoAction(changes: redoChanges, previousLastCheckedItemID: lastCheckedItemID)
        redoStack.append(redoAction)

        // Restore previous state
        for change in action.changes {
            if let index = items.firstIndex(where: { $0.id == change.id }) {
                items[index] = items[index].withCheckedState(change.wasChecked)
            }
        }
        lastCheckedItemID = action.previousLastCheckedItemID

        scheduleAutoSave()
        if let url = markdownFileURL {
            _ = ProgressPersistence.shared.saveProgress(for: self, markdownFileURL: url)
        }
    }

    /// Redo the last undone action
    func redo() {
        guard let action = redoStack.popLast() else { return }

        // Record current state for undo
        var undoChanges: [(id: String, wasChecked: Bool)] = []
        for change in action.changes {
            if let index = items.firstIndex(where: { $0.id == change.id }) {
                undoChanges.append((id: change.id, wasChecked: items[index].isChecked))
            }
        }
        let undoAction = CheckboxUndoAction(changes: undoChanges, previousLastCheckedItemID: lastCheckedItemID)
        undoStack.append(undoAction)

        // Apply redo state
        for change in action.changes {
            if let index = items.firstIndex(where: { $0.id == change.id }) {
                items[index] = items[index].withCheckedState(change.wasChecked)
            }
        }
        lastCheckedItemID = action.previousLastCheckedItemID

        scheduleAutoSave()
        if let url = markdownFileURL {
            _ = ProgressPersistence.shared.saveProgress(for: self, markdownFileURL: url)
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
        startFileWatcher()

        // Get file modification date
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            self.fileModificationDate = modificationDate
        }

        // Update last accessed date
        self.lastAccessedDate = Date()

        // Load saved progress and reconcile with new items
        let savedProgress = ProgressPersistence.shared.loadProgress(for: fileURL)
        let (reconciledItems, reconciledHeaders) = ProgressPersistence.shared.reconcile(
            newItems: newItems,
            with: savedProgress
        )

        // If no expanded headers were preserved, default to expanding all headers
        if reconciledHeaders.isEmpty {
            let headerIDs = newItems.filter { $0.type == .header }.map { $0.id }
            expandedHeaders = Set(headerIDs)
        } else {
            expandedHeaders = reconciledHeaders
        }

        self.items = reconciledItems
    }
    
    /// Schedule auto-save with debouncing
    private func scheduleAutoSave() {
        saveCancellable?.cancel()
        
        saveCancellable = Just(())
            .delay(for: .seconds(saveDebounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.saveToFile()
            }
    }
    
    /// Save the document content back to the markdown file
    private func saveToFile() {
        guard let url = markdownFileURL else { return }
        
        isSaving = true
        let content = MarkdownParser.shared.reconstruct(from: items)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.lastSaveTime = Date()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSaving = false
                    // Handle error
                }
            }
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
        // Find the most recently checked item (by lastCheckedItemID), or fall back to last in document order
        let lastChecked: ContentItem?
        if let lastID = lastCheckedItemID,
           let item = items.first(where: { $0.id == lastID && $0.isChecked }) {
            lastChecked = item
        } else {
            lastChecked = checkedItems.last
        }

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