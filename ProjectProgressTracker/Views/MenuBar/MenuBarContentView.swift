//
//  MenuBarContentView.swift
//  ProjectProgressTracker
//
//  Created by Alex on [[DATE]].
//

import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var projectManager = ProjectManager.shared
    @State private var selectedProjectID: UUID?
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Button("Show Project Panel") {
                if let project = ProjectManager.shared.activeProject ?? ProjectManager.shared.projects.first {
                    let anchor = NSEvent.mouseLocation // best guess for menu bar icon location
                    FloatingPanelController.shared.show(
                        content: ContentListView(document: project)
                            .frame(width: 440, height: 380), // ensure content itself wants to be wide!
                        anchorPoint: anchor,
                        preferredWidth: 440,
                        preferredHeight: 400
                    )
                }
            }
            .padding()
            Text("Use the button above to show the full-width hierarchy panel.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .frame(width: 280, height: 350)
        .onAppear {
            selectedProjectID = projectManager.activeProject?.id
        }
        .onChange(of: projectManager.activeProject?.id) { newID in
            selectedProjectID = newID
        }
    }
    
    private var selectedProject: Document? {
        guard let id = selectedProjectID else { return nil }
        return projectManager.projects.first { $0.id == id }
    }
    
    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Check if a window with ContentView is already open
        if let window = NSApp.windows.first(where: {
            // Check if the window's contentViewController is hosting our ContentView
            guard let controller = $0.contentViewController else { return false }
            return String(describing: type(of: controller)).contains("HostingController<ContentView>")
        }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // If no window is found, open a new one.
            openWindow(id: "main")
        }
    }
}

#Preview {
    MenuBarContentView()
}