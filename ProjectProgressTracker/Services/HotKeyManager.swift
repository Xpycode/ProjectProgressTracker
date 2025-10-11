//
//  HotKeyManager.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 11.10.25.
//

import AppKit

class HotKeyManager {
    private var eventMonitor: Any?

    func register() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+Shift+P
            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.keyCode == 35 {
                NotificationCenter.default.post(name: .toggleMenuBarPanel, object: nil)
            }
        }
    }

    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

extension Notification.Name {
    static let toggleMenuBarPanel = Notification.Name("toggleMenuBarPanel")
}
