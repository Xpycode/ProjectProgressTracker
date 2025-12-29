//
//  MenuBarController.swift
//  ProjectProgressTracker
//
//  Created by Claude on 08.10.25.
//

import AppKit
import SwiftUI
import Combine

class MenuBarController: ObservableObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func setupMenuBar() {
        // Make sure we're on the main thread
        assert(Thread.isMainThread, "setupMenuBar must be called on main thread")

        // Important: Remove any existing status item first
        if let existingItem = statusItem {
            NSStatusBar.system.removeStatusItem(existingItem)
            statusItem = nil
        }

        // Create status item with variable length to accommodate the icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusItem = statusItem {
            statusItem.isVisible = true

            if let button = statusItem.button {
                // Clear any existing content
                button.title = ""
                button.image = nil

                // Set initial icon
                updateIcon(percentage: 0)

                button.action = #selector(togglePopover)
                button.target = self
                button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            }
        }

        // Observe project changes to update icon
        ProjectManager.shared.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    let percentage = ProjectManager.shared.activeProject?.completionPercentage ?? 0
                    self?.updateIcon(percentage: percentage)
                }
            }
            .store(in: &cancellables)

        // Setup popover
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarPanelView()
                .environmentObject(ZoomManager())
        )

        // Listen for global hotkey
        NotificationCenter.default.publisher(for: .toggleMenuBarPanel)
            .sink { [weak self] _ in
                self?.togglePopover()
            }
            .store(in: &cancellables)
    }

    private func updateIcon(percentage: Double) {
        guard let button = statusItem?.button else { return }

        // Use the icon renderer to create the proper icon
        let icon = MenuBarIconRenderer.createIcon(completionPercentage: percentage)
        button.image = icon

        // Ensure no title is set when using an image
        button.title = ""
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Make sure the button's window is key before showing the popover
                button.window?.makeKeyAndOrderFront(nil)

                // Show the popover anchored to the status item button
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                // Activate the app to bring it to front
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
