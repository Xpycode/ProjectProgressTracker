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

    @Published var projects: [Document] = []
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
    }
    
    /// Add a new project
    func addProject(_ document: Document) {
        // Observe changes in the document's completion percentage
        let cancellable = document.$items
            .sink { [weak self] _ in
                // Trigger a change in projects to refresh UI
                self?.objectWillChange.send()
            }

        cancellables[document.id] = cancellable

        projects.append(document)

        // If this is the first project, make it active
        if projects.count == 1 {
            activeProjectID = document.id
        }

        // Sort projects after adding
        sortProjects()
    }
    
    /// Remove a project
    func removeProject(_ document: Document) {
        // Cancel and remove the subscription
        cancellables[document.id]?.cancel()
        cancellables.removeValue(forKey: document.id)
        
        projects.removeAll { $0.id == document.id }
        
        // If we removed the active project, select another one
        if activeProjectID == document.id {
            activeProjectID = projects.first?.id
        }
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
                guard let date1 = doc1.lastCheckedDate,
                      let date2 = doc2.lastCheckedDate else {
                    // Put documents without lastCheckedDate at the end
                    if doc1.lastCheckedDate == nil && doc2.lastCheckedDate == nil {
                        return false
                    }
                    return doc1.lastCheckedDate != nil
                }
                return date1 > date2
            }
        }
    }
}