//
//  ProjectProgressTrackerApp.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

@main
struct ProjectProgressTrackerApp: App {
    @StateObject private var zoomManager = ZoomManager()
    @StateObject private var menuBarController = MenuBarController()

    init() {
        // Restore open files when app launches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ProjectManager.shared.restoreOpenFiles()
        }
    }

    var body: some Scene {
        Window("Project Progress Tracker", id: "main") {
            ContentView()
                .environmentObject(zoomManager)
                .onAppear {
                    menuBarController.setupMenuBar()
                }
        }
        .commands {
            // Remove the default "New" menu item as it's not needed
            CommandGroup(replacing: .newItem) {}

            // Add a custom "File" menu
            CommandMenu("File") {
                Button("Open Markdown File...") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Close Project") {
                    if let activeProject = ProjectManager.shared.activeProject {
                        ProjectManager.shared.removeProject(activeProject)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(ProjectManager.shared.activeProject == nil)
            }
            
            // Add a "View" menu for zoom controls
            CommandMenu("View") {
                Button("Zoom In") {
                    zoomManager.bigger()
                }
                .keyboardShortcut("=", modifiers: .command)
                
                Button("Zoom Out") {
                    zoomManager.smaller()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Reset Zoom") {
                    zoomManager.reset()
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            // Add a "Project" menu for navigation
            CommandMenu("Project") {
                Button("Next Project") {
                    ProjectManager.shared.switchToNextProject()
                }
                .keyboardShortcut(.tab, modifiers: .control)
                
                Button("Previous Project") {
                    ProjectManager.shared.switchToPreviousProject()
                }
                .keyboardShortcut(.tab, modifiers: [.control, .shift])
                
                Divider()
                
                // Shortcuts for Cmd+1 to Cmd+9
                ForEach(0..<min(ProjectManager.shared.projects.count, 9), id: \.self) { index in
                    Button(ProjectManager.shared.projects[index].filename) {
                        ProjectManager.shared.switchToProject(at: index)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }

            // Add to existing Window menu
            CommandGroup(after: .windowArrangement) {
                Button("Show Raw Markdown Content") {
                    NotificationCenter.default.post(name: .showRawMarkdown, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            // Add a "Help" menu
            CommandMenu("Help") {
                Button("Keyboard Shortcuts") {
                    // Open the shortcuts window
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
                        styleMask: [.titled, .closable],
                        backing: .buffered,
                        defer: false
                    )
                    window.center()
                    window.title = "Keyboard Shortcuts"
                    window.contentView = NSHostingView(rootView: ShortcutsView())
                    window.makeKeyAndOrderFront(nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}