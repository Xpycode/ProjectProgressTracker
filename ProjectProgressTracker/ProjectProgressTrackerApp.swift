//
//  ProjectProgressTrackerApp.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

@main
struct ProjectProgressTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var zoomManager = ZoomManager()
    @State private var shortcutsWindow: NSWindow?
    @State private var settingsWindow: NSWindow?
    private let hotKeyManager = HotKeyManager()

    init() {
        print("🚀 App initializing...")

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
                    print("🚀 ContentView appeared, setting up hotkey...")
                    // Register hotkey
                    hotKeyManager.register()
                }
        }
        .commands {
            // MARK: - App Menu
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    showSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // MARK: - File Menu
            CommandGroup(replacing: .newItem) {
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

            // MARK: - Edit Menu (for copy support)
            CommandGroup(after: .pasteboard) {
                // The Cmd+C shortcut is handled in ContentListView
                // This ensures it appears in the menu
            }

            // MARK: - View Menu
            CommandGroup(after: .toolbar) {
                Divider()
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

                Divider()

                Button("Show Raw Markdown Content") {
                    NotificationCenter.default.post(name: .showRawMarkdown, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // MARK: - Navigate Menu (Custom)
            CommandMenu("Navigate") {
                Button("Next Main Header") {
                    NotificationCenter.default.post(name: .navigateToNextHeader, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .command)

                Button("Previous Main Header") {
                    NotificationCenter.default.post(name: .navigateToPreviousHeader, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .command)

                Divider()

                Button("Next Sub-Header") {
                    NotificationCenter.default.post(name: .navigateToNextSubHeader, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .option)

                Button("Previous Sub-Header") {
                    NotificationCenter.default.post(name: .navigateToPreviousSubHeader, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .option)

                Divider()

                Button("Next Parent Checkbox") {
                    NotificationCenter.default.post(name: .navigateToNextBoldCheckbox, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])

                Button("Previous Parent Checkbox") {
                    NotificationCenter.default.post(name: .navigateToPreviousBoldCheckbox, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            }

            // MARK: - Project Menu (Custom)
            CommandMenu("Project") {
                Button("Next Project") {
                    ProjectManager.shared.switchToNextProject()
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Previous Project") {
                    ProjectManager.shared.switchToPreviousProject()
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Divider()
                
                // Shortcuts for Cmd+1 to Cmd+9
                ForEach(0..<min(ProjectManager.shared.projects.count, 9), id: \.self) { index in
                    Button(ProjectManager.shared.projects[index].filename) {
                        ProjectManager.shared.switchToProject(at: index)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
            
            // MARK: - Help Menu
            CommandGroup(replacing: .help) {
                Button("Keyboard Shortcuts") {
                    showShortcutsWindow()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }

    private func showShortcutsWindow() {
        // If window already exists and is visible, just bring it to front
        if let window = shortcutsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Create new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Keyboard Shortcuts"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ShortcutsView())
        window.makeKeyAndOrderFront(nil)

        shortcutsWindow = window
    }

    private func showSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
    }
}