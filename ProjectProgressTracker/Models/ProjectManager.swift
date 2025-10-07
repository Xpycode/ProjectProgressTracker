//
//  ProjectManager.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import Combine

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
    
    private var cancellables = [UUID: AnyCancellable]()
    
    private init() {
        // Load the last active project ID from UserDefaults
        if let activeProjectIDString = UserDefaults.standard.string(forKey: "ActiveProjectID"),
           let uuid = UUID(uuidString: activeProjectIDString) {
            activeProjectID = uuid
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
}