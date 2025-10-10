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
            }
        }
    }
}