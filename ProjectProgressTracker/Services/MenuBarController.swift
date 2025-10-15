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

    private init() {
        print("🔧 MenuBarController: Singleton initialized")
    }

    func setupMenuBar() {
        print("🔧 MenuBarController: Setting up menu bar...")

        // Make sure we're on the main thread
        assert(Thread.isMainThread, "setupMenuBar must be called on main thread")

        // Important: Remove any existing status item first
        if let existingItem = statusItem {
            NSStatusBar.system.removeStatusItem(existingItem)
            statusItem = nil
            print("🔧 MenuBarController: Removed existing status item")
        }

        // Create status item with variable length to accommodate the icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("🔧 MenuBarController: Status item created: \(statusItem != nil)")
        print("🔧 MenuBarController: Status bar: \(NSStatusBar.system)")

        if let statusItem = statusItem {
            statusItem.isVisible = true
            print("🔧 MenuBarController: Status item visibility set to true")

            if let button = statusItem.button {
                print("🔧 MenuBarController: Button found, setting up...")

                // Clear any existing content
                button.title = ""
                button.image = nil

                // Set initial icon
                updateIcon(percentage: 0)

                print("🔧 MenuBarController: Button title set to: '\(button.title)'")
                print("🔧 MenuBarController: Button image set: \(button.image != nil)")
                print("🔧 MenuBarController: Button frame: \(button.frame)")
                print("🔧 MenuBarController: Button superview: \(button.superview != nil)")

                button.action = #selector(togglePopover)
                button.target = self
                button.sendAction(on: [.leftMouseDown, .rightMouseDown])

                print("🔧 MenuBarController: Menu bar setup complete!")
            } else {
                print("❌ MenuBarController: Failed to get button from status item")
            }
        } else {
            print("❌ MenuBarController: Failed to create status item")
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
        print("🔧 MenuBarController: togglePopover called")

        guard let button = statusItem?.button else {
            print("❌ MenuBarController: No button found in togglePopover")
            return
        }

        print("🔧 MenuBarController: Button exists, popover: \(popover != nil)")

        if let popover = popover {
            if popover.isShown {
                print("🔧 MenuBarController: Closing popover")
                popover.performClose(nil)
            } else {
                print("🔧 MenuBarController: Showing popover")

                // Make sure the button's window is key before showing the popover
                button.window?.makeKeyAndOrderFront(nil)

                // Show the popover anchored to the status item button
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                // Activate the app to bring it to front
                NSApp.activate(ignoringOtherApps: true)

                print("🔧 MenuBarController: Popover shown: \(popover.isShown)")
            }
        }
    }
}