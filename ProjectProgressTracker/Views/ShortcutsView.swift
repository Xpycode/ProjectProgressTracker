//
//  ShortcutsView.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 10.10.25.
//

import SwiftUI

struct ShortcutsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Keyboard Shortcuts")
                    .font(.largeTitle)
                    .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 15) {
                    Text("File")
                        .font(.headline)
                    ShortcutRow(keys: "⌘ O", description: "Open New File")
                    ShortcutRow(keys: "⌘ W", description: "Close Current Project")

                    Divider()

                    Text("Projects")
                        .font(.headline)
                    ShortcutRow(keys: "⌘ ]", description: "Next Project")
                    ShortcutRow(keys: "⌘ [", description: "Previous Project")
                    ShortcutRow(keys: "⌘ 1-9", description: "Switch to Specific Project")

                    Divider()

                    Text("Navigation")
                        .font(.headline)
                    ShortcutRow(keys: "⌘ ↓", description: "Next Main Header")
                    ShortcutRow(keys: "⌘ ↑", description: "Previous Main Header")
                    ShortcutRow(keys: "⌥ ↓", description: "Next Sub-Header")
                    ShortcutRow(keys: "⌥ ↑", description: "Previous Sub-Header")
                    ShortcutRow(keys: "⌘ ⌥ ↓", description: "Next Parent Checkbox")
                    ShortcutRow(keys: "⌘ ⌥ ↑", description: "Previous Parent Checkbox")

                    Divider()

                    Text("View")
                        .font(.headline)
                    ShortcutRow(keys: "⌘ R", description: "Show Raw Markdown")
                    ShortcutRow(keys: "⌘ =", description: "Zoom In")
                    ShortcutRow(keys: "⌘ -", description: "Zoom Out")
                    ShortcutRow(keys: "⌘ 0", description: "Reset Zoom")

                    Divider()

                    Text("Editing")
                        .font(.headline)
                    ShortcutRow(keys: "⌘ C", description: "Copy Selected Line")
                    ShortcutRow(keys: "Space", description: "Toggle Checkbox")
                }

                Spacer()
            }
            .padding(30)
        }
        .frame(width: 400, height: 550)
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 100, alignment: .trailing)
            
            Text(description)
        }
    }
}

#Preview {
    ShortcutsView()
}
