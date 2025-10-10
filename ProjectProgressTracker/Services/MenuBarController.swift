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
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            updateIcon(percentage: ProjectManager.shared.activeProject?.completionPercentage ?? 0)
            button.action = #selector(togglePopover)
            button.target = self
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
        popover?.contentSize = NSSize(width: 380, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarPanelView()
                .environmentObject(ZoomManager())
        )
    }

    private func updateIcon(percentage: Double) {
        guard let button = statusItem?.button else { return }

        let icon = MenuBarIconRenderer.createIcon(completionPercentage: percentage)
        button.image = icon
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
