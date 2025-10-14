//
//  AppSettings.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import Foundation
import AppKit
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var defaultSortOption: SortOption {
        didSet {
            UserDefaults.standard.set(defaultSortOption.rawValue, forKey: "DefaultSortOption")
        }
    }

    @Published var isGlobalHotkeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGlobalHotkeyEnabled, forKey: "isGlobalHotkeyEnabled")
        }
    }
    
    @Published var globalHotkeyKeyCode: UInt16 {
        didSet {
            UserDefaults.standard.set(Int(globalHotkeyKeyCode), forKey: "globalHotkeyKeyCode")
        }
    }
    
    @Published var globalHotkeyModifiers: NSEvent.ModifierFlags {
        didSet {
            UserDefaults.standard.set(globalHotkeyModifiers.rawValue, forKey: "globalHotkeyModifiers")
        }
    }

    private init() {
        // Load the default sort option from UserDefaults, or use .lastAccessed as a default
        if let sortOptionString = UserDefaults.standard.string(forKey: "DefaultSortOption"),
           let savedSortOption = SortOption(rawValue: sortOptionString) {
            self.defaultSortOption = savedSortOption
        } else {
            self.defaultSortOption = .lastAccessed
        }

        // Global Hotkey Enabled state
        self.isGlobalHotkeyEnabled = UserDefaults.standard.object(forKey: "isGlobalHotkeyEnabled") as? Bool ?? true
        
        // Global Hotkey Key Code
        let savedKeyCode = UInt16(UserDefaults.standard.integer(forKey: "globalHotkeyKeyCode"))
        if savedKeyCode == 0 {
            self.globalHotkeyKeyCode = 35 // Default 'P'
        } else {
            self.globalHotkeyKeyCode = savedKeyCode
        }
        
        // Global Hotkey Modifiers
        let savedModifiersRaw = UserDefaults.standard.integer(forKey: "globalHotkeyModifiers")
        if savedModifiersRaw == 0 {
            self.globalHotkeyModifiers = [.command, .shift] // Default Cmd+Shift
        } else {
            self.globalHotkeyModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiersRaw))
        }
    }
}
