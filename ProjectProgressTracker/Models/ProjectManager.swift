//
//  ProjectManager.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import Combine

enum SortOption: String, CaseIterable {
    case name = "Name"
    case date = "Date Modified"
    case lastAccessed = "Last Accessed"
    case lastChecked = "Last Checked"
}

class ProjectManager: ObservableObject {
    static let shared = ProjectManager()

    @Published private(set) var projects: [Document] = []
    @Published var activeProjectID: UUID? {
        didSet {
            // Save the active project ID to UserDefaults
            if let id = activeProjectID {
                UserDefaults.standard.set(id.uuidString, forKey: "ActiveProjectID")
            } else {
                UserDefaults.standard.removeObject(forKey: "ActiveProjectID")
            }
        }
    }
    @Published var sortOption: SortOption = .lastAccessed {
        didSet {
            UserDefaults.standard.set(sortOption.rawValue, forKey: "ProjectSortOption")
            sortProjects()
        }
    }

    private var cancellables = [UUID: AnyCancellable]()
    
    private init() {
        // Load the last active project ID from UserDefaults
        if let activeProjectIDString = UserDefaults.standard.string(forKey: "ActiveProjectID"),
           let uuid = UUID(uuidString: activeProjectIDString) {
            activeProjectID = uuid
        }

        // Load the sort option from UserDefaults
        if let sortOptionString = UserDefaults.standard.string(forKey: "ProjectSortOption"),
           let savedSortOption = SortOption(rawValue: sortOptionString) {
            sortOption = savedSortOption
        }

        // Clean up old path-based storage (migration)
        UserDefaults.standard.removeObject(forKey: "OpenFileURLs")
    }

    /// Save the list of open file bookmarks to UserDefaults
    private func saveOpenFiles() {
        var bookmarks: [Data] = []

        for project in projects {
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

        for bookmarkData in savedBookmarks {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                // Skip if already loaded
                if isProjectLoaded(with: url) {
                    continue
                }

                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }

                // Load the file
                loadFileInBackground(from: url, isSecurityScoped: true)

            } catch {
                // Failed to resolve bookmark
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
                    // If this was a security-scoped resource, start maintaining access
                    if isSecurityScoped {
                        document.startAccessingSecurityScopedResource()
                    }
                }
            } catch {
                // Failed to restore file
                if isSecurityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    /// Add a new project
    func addProject(_ document: Document) {
        // Observe changes in the document's items and lastCheckedDate
        let itemsCancellable = document.$items
            .sink { [weak self] _ in
                // Trigger a change in projects to refresh UI
                self?.objectWillChange.send()
            }

        let lastCheckedCancellable = document.$lastCheckedDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Re-sort when lastCheckedDate changes (if sorting by lastChecked)
                if self?.sortOption == .lastChecked {
                    // Use async to ensure the property has been updated
                    DispatchQueue.main.async {
                        self?.sortProjects()
                    }
                }
            }

        // Store both cancellables using a set
        let combinedCancellable = AnyCancellable {
            itemsCancellable.cancel()
            lastCheckedCancellable.cancel()
        }

        cancellables[document.id] = combinedCancellable

        projects.append(document)

        // If this is the first project, make it active
        if projects.count == 1 {
            activeProjectID = document.id
        }

        // Sort projects after adding
        sortProjects()

        // Save the updated file list
        saveOpenFiles()
    }
    
    /// Remove a project
    func removeProject(_ document: Document) {
        // Stop accessing security-scoped resource
        document.stopAccessingSecurityScopedResource()

        // Cancel and remove the subscription
        cancellables[document.id]?.cancel()
        cancellables.removeValue(forKey: document.id)

        projects.removeAll { $0.id == document.id }

        // If we removed the active project, select another one
        if activeProjectID == document.id {
            activeProjectID = projects.first?.id
        }

        // Save the updated file list
        saveOpenFiles()
    }
    
    /// Set active project
    func setActiveProject(_ document: Document) {
        activeProjectID = document.id
        // Update last accessed date when switching to this project
        document.lastAccessedDate = Date()
        sortProjects()
    }
    
    /// Get active project
    var activeProject: Document? {
        guard let activeID = activeProjectID else { return projects.first }
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

    /// Sort projects based on the current sort option
    private func sortProjects() {
        switch sortOption {
        case .name:
            // Sort alphabetically by filename (A-Z)
            projects.sort { $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending }

        case .date:
            // Sort by file modification date (most recent first)
            projects.sort { (doc1, doc2) in
                guard let date1 = doc1.fileModificationDate,
                      let date2 = doc2.fileModificationDate else {
                    // Put documents without dates at the end
                    if doc1.fileModificationDate == nil && doc2.fileModificationDate == nil {
                        return false
                    }
                    return doc1.fileModificationDate != nil
                }
                return date1 > date2
            }

        case .lastAccessed:
            // Sort by last accessed date (most recent first)
            projects.sort { $0.lastAccessedDate > $1.lastAccessedDate }

        case .lastChecked:
            // Sort by last checked date (most recent first)
            projects.sort { (doc1, doc2) in
                // Handle nil cases explicitly
                switch (doc1.lastCheckedDate, doc2.lastCheckedDate) {
                case (.some(let date1), .some(let date2)):
                    // Both have dates - compare them (most recent first)
                    return date1 > date2
                case (.some, .none):
                    // doc1 has a date, doc2 doesn't - doc1 comes first
                    return true
                case (.none, .some):
                    // doc2 has a date, doc1 doesn't - doc2 comes first
                    return false
                case (.none, .none):
                    // Neither has a date - maintain current order
                    return false
                }
            }
        }
    }
}