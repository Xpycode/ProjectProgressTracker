//
//  ProjectManager.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import Combine

enum FilterState: String, CaseIterable {
    case all = "All"
    case unchecked = "Unchecked"
    case checked = "Checked"
}

enum SortOption: String, CaseIterable {
    case name = "Name"
    case date = "Date"
    case lastAccessed = "Accessed"
    case lastChecked = "Checked"
}

class ProjectManager: ObservableObject {
    static let shared = ProjectManager()

    @Published private(set) var projects: [Document] = []
    @Published var activeProjectID: UUID? {
        didSet {
            if let id = activeProjectID {
                UserDefaults.standard.set(id.uuidString, forKey: "ActiveProjectID")
            } else {
                UserDefaults.standard.removeObject(forKey: "ActiveProjectID")
            }
        }
    }
    
    @Published var searchText: String = ""
    @Published var filterState: FilterState = .all
    @Published var sortOption: SortOption = .lastAccessed {
        didSet {
            UserDefaults.standard.set(sortOption.rawValue, forKey: "ProjectSortOption")
            objectWillChange.send()
        }
    }
    @Published var sortAscending: Bool = false {
        didSet {
            UserDefaults.standard.set(sortAscending, forKey: "ProjectSortAscending")
            objectWillChange.send()
        }
    }

    private var cancellables = [UUID: AnyCancellable]()
    
    private init() {
        if let activeProjectIDString = UserDefaults.standard.string(forKey: "ActiveProjectID"),
           let uuid = UUID(uuidString: activeProjectIDString) {
            activeProjectID = uuid
        }

        if let sortOptionString = UserDefaults.standard.string(forKey: "ProjectSortOption"),
           let savedSortOption = SortOption(rawValue: sortOptionString) {
            sortOption = savedSortOption
        } else {
            // Use the default from AppSettings if no session-specific one is saved
            sortOption = AppSettings.shared.defaultSortOption
        }
        
        sortAscending = UserDefaults.standard.bool(forKey: "ProjectSortAscending")

        UserDefaults.standard.removeObject(forKey: "OpenFileURLs")
    }

    var sortedProjects: [Document] {
        return projects.sorted { (doc1, doc2) in
            switch sortOption {
            case .name:
                return sortAscending
                    ? doc1.filename.localizedCaseInsensitiveCompare(doc2.filename) == .orderedAscending
                    : doc1.filename.localizedCaseInsensitiveCompare(doc2.filename) == .orderedDescending
            case .date:
                let date1 = doc1.fileModificationDate
                let date2 = doc2.fileModificationDate
                if date1 == nil && date2 != nil { return false }
                if date1 != nil && date2 == nil { return true }
                guard let d1 = date1, let d2 = date2 else { return false }
                return sortAscending ? d1 < d2 : d1 > d2
            case .lastAccessed:
                return sortAscending ? doc1.lastAccessedDate < doc2.lastAccessedDate : doc1.lastAccessedDate > doc2.lastAccessedDate
            case .lastChecked:
                let date1 = doc1.lastCheckedDate
                let date2 = doc2.lastCheckedDate
                if date1 == nil && date2 != nil { return false }
                if date1 != nil && date2 == nil { return true }
                guard let d1 = date1, let d2 = date2 else { return false }
                return sortAscending ? d1 < d2 : d1 > d2
            }
        }
    }
    
    func selectSortOption(_ option: SortOption) {
        if self.sortOption == option {
            sortAscending.toggle()
        } else {
            self.sortOption = option
            self.sortAscending = (option == .name)
        }
    }
    
    /// Save the list of open file bookmarks to UserDefaults
    private func saveOpenFiles() {
        var bookmarks: [Data] = []

        // Use the currently displayed order to save bookmarks
        for project in sortedProjects {
            guard let url = project.fileURL else {
                continue
            }

            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                bookmarks.append(bookmarkData)
            } catch {
                // Failed to create bookmark for this file
            }
        }

        UserDefaults.standard.set(bookmarks, forKey: "OpenFileBookmarks")
    }

    /// Restore previously open files from UserDefaults using bookmarks
    func restoreOpenFiles() {
        guard let savedBookmarks = UserDefaults.standard.array(forKey: "OpenFileBookmarks") as? [Data] else {
            return
        }

        var restoredProjects: [Document] = []
        let group = DispatchGroup()

        for bookmarkData in savedBookmarks {
            group.enter()
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                guard url.startAccessingSecurityScopedResource() else {
                    group.leave()
                    continue
                }

                let content = try String(contentsOf: url, encoding: .utf8)
                let parsedItems = MarkdownParser.shared.parse(content)

                let document = Document()
                document.loadItems(parsedItems, filename: url.lastPathComponent, fileURL: url)
                document.startAccessingSecurityScopedResource()
                restoredProjects.append(document)
                
            } catch {
                // Failed to resolve bookmark
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.projects = restoredProjects
            // Add projects and set up observers
            restoredProjects.forEach { doc in
                self.setupObservers(for: doc)
            }
        }
    }

    /// Load a file in the background and add it to projects
    private func loadFileInBackground(from url: URL, isSecurityScoped: Bool = false) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let parsedItems = MarkdownParser.shared.parse(content)

                let document = Document()
                document.loadItems(parsedItems, filename: url.lastPathComponent, fileURL: url)

                DispatchQueue.main.async {
                    self.addProject(document)
                    if isSecurityScoped {
                        document.startAccessingSecurityScopedResource()
                    }
                }
            } catch {
                if isSecurityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    private func setupObservers(for document: Document) {
        // Check if document is still valid before setting up observers
        guard projects.contains(where: { $0.id == document.id }) || cancellables[document.id] == nil else {
            return
        }

        let itemsCancellable = document.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak document] _ in
                guard let self = self, let document = document else { return }
                // Verify document still exists in projects array
                if self.projects.contains(where: { $0.id == document.id }) {
                    self.objectWillChange.send()
                }
            }

        let lastCheckedCancellable = document.$lastCheckedDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak document] _ in
                guard let self = self, let document = document else { return }
                // Verify document still exists and sort option requires update
                if self.projects.contains(where: { $0.id == document.id }) && self.sortOption == .lastChecked {
                    self.objectWillChange.send()
                }
            }

        let combinedCancellable = AnyCancellable {
            itemsCancellable.cancel()
            lastCheckedCancellable.cancel()
        }

        cancellables[document.id] = combinedCancellable
    }

    /// Add a new project
    func addProject(_ document: Document) {
        guard !projects.contains(where: { $0.fileURL == document.fileURL }) else { return }
        
        setupObservers(for: document)
        projects.append(document)

        if projects.count == 1 {
            activeProjectID = document.id
        }

        saveOpenFiles()
    }
    
    /// Remove a project
    func removeProject(_ document: Document) {
        document.stopAccessingSecurityScopedResource()
        cancellables[document.id]?.cancel()
        cancellables.removeValue(forKey: document.id)
        projects.removeAll { $0.id == document.id }

        if activeProjectID == document.id {
            activeProjectID = sortedProjects.first?.id
        }

        saveOpenFiles()
    }
    
    /// Set active project
    func setActiveProject(_ document: Document) {
        activeProjectID = document.id
        document.lastAccessedDate = Date()
        if sortOption == .lastAccessed {
            objectWillChange.send()
        }
    }
    
    /// Get active project
    var activeProject: Document? {
        guard let activeID = activeProjectID else { return sortedProjects.first }
        return projects.first { $0.id == activeID }
    }
    
    /// Check if a project is active
    func isActive(_ document: Document) -> Bool {
        return document.id == activeProjectID
    }
    
    /// Check if a project is already loaded
    func isProjectLoaded(with url: URL) -> Bool {
        return projects.contains { project in
            project.fileURL == url
        }
    }

    /// Switch to the next project in the list
    func switchToNextProject() {
        let sorted = sortedProjects
        guard !sorted.isEmpty else { return }
        guard let activeID = activeProjectID, let currentIndex = sorted.firstIndex(where: { $0.id == activeID }) else {
            return
        }

        let nextIndex = (currentIndex + 1) % sorted.count
        setActiveProject(sorted[nextIndex])
    }

    /// Switch to the previous project in the list
    func switchToPreviousProject() {
        let sorted = sortedProjects
        guard !sorted.isEmpty else { return }
        guard let activeID = activeProjectID, let currentIndex = sorted.firstIndex(where: { $0.id == activeID }) else {
            return
        }

        let prevIndex = (currentIndex - 1 + sorted.count) % sorted.count
        setActiveProject(sorted[prevIndex])
    }

    /// Switch to a project at a specific index
    func switchToProject(at index: Int) {
        let sorted = sortedProjects
        guard sorted.indices.contains(index) else { return }
        setActiveProject(sorted[index])
    }
}