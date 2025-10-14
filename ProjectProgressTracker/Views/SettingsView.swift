//
//  SettingsView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings.shared

    var body: some View {
        TabView {
            // General Settings Tab
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // Shortcuts Settings Tab
            shortcutsSettings
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 400, height: 200)
    }

    private var generalSettings: some View {
        Form {
            Picker("Default Project Sort:", selection: $appSettings.defaultSortOption) {
                ForEach(SortOption.allCases, id: \.self) {
                    option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Spacer()
        }
        .padding()
    }

    private var shortcutsSettings: some View {
        Form {
            Toggle("Enable Global Hotkey", isOn: $appSettings.isGlobalHotkeyEnabled)
            
            HStack {
                Text("Show/Hide Menu Bar:")
                Spacer()
                ShortcutRecorderView(
                    keyCode: $appSettings.globalHotkeyKeyCode,
                    modifierFlags: $appSettings.globalHotkeyModifiers
                )
                .disabled(!appSettings.isGlobalHotkeyEnabled)
            }
        }
        .padding()
    }
}

// A view to record a keyboard shortcut
struct ShortcutRecorderView: View {
    @Binding var keyCode: UInt16
    @Binding var modifierFlags: NSEvent.ModifierFlags
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        Button(action: {
            isRecording = true
            // Remove old monitor if exists
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            // Capture the next key down event
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                self.keyCode = event.keyCode
                self.modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                self.isRecording = false
                // Remove the monitor after capturing
                if let monitor = self.eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    self.eventMonitor = nil
                }
                return nil
            }
        }) {
            Text(isRecording ? "Recording..." : shortcutText)
                .frame(minWidth: 100)
        }
        .onDisappear {
            // Clean up monitor when view disappears
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }

    private var shortcutText: String {
        let modifiers = modifierFlags.description
        guard let key = keyMap[keyCode] else {
            return "Record Shortcut"
        }
        return "\(modifiers)\(key)"
    }
}

// Extension to make modifier flags more readable
extension NSEvent.ModifierFlags {
    var description: String {
        var desc = ""
        if contains(.command) { desc += "⌘" }
        if contains(.shift) { desc += "⇧" }
        if contains(.option) { desc += "⌥" }
        if contains(.control) { desc += "⌃" }
        return desc
    }
}

// Complete map of key codes to characters
private let keyMap: [UInt16: String] = [
    // Letters
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
    11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
    31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",

    // Numbers
    18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 25: "9", 26: "7", 28: "8", 29: "0",

    // Symbols
    24: "=", 27: "-", 30: "]", 33: "[", 39: "'", 41: ";", 42: "\\", 43: ",", 44: "/", 47: ".", 50: "`",

    // Special keys
    36: "↩", 48: "⇥", 49: "␣", 51: "⌫", 53: "⎋",

    // Function keys
    122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
    101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
    106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",

    // Arrow keys
    123: "←", 124: "→", 125: "↓", 126: "↑",

    // Navigation keys
    115: "Home", 116: "Page Up", 117: "⌦", 119: "End", 121: "Page Down",

    // Keypad
    65: ".", 67: "*", 69: "+", 75: "/", 76: "↩", 78: "-", 81: "=",
    82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9"
]


#Preview {
    SettingsView()
}