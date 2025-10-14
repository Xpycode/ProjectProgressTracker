//
//  HotKeyManager.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 11.10.25.
//

import AppKit
import Combine

class HotKeyManager {
    private var eventMonitor: Any?
    private var settingsCancellable: AnyCancellable?

    init() {
        // Observe changes in AppSettings
        settingsCancellable = AppSettings.shared.objectWillChange.sink { [weak self] _ in
            // Use DispatchQueue.main.async to ensure the settings have been updated before we re-register
            DispatchQueue.main.async {
                self?.updateRegistration()
            }
        }
    }

    func register() {
        guard AppSettings.shared.isGlobalHotkeyEnabled else { return }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let settings = AppSettings.shared
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == settings.globalHotkeyModifiers && event.keyCode == settings.globalHotkeyKeyCode {
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
    
    func updateRegistration() {
        unregister()
        register()
    }
}

extension Notification.Name {
    static let toggleMenuBarPanel = Notification.Name("toggleMenuBarPanel")
}
