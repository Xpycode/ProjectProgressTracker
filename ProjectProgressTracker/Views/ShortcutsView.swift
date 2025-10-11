//
//  ShortcutsView.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 10.10.25.
//

import SwiftUI

struct ShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 15) {
                ShortcutRow(keys: "⌘ O", description: "Open New File")
                ShortcutRow(keys: "⌘ W", description: "Close Current Project")
                Divider()
                ShortcutRow(keys: "⌃ Tab", description: "Next Project")
                ShortcutRow(keys: "⌃ ⇧ Tab", description: "Previous Project")
                ShortcutRow(keys: "⌘ 1-9", description: "Switch to Specific Project")
                Divider()
                ShortcutRow(keys: "⌘ R", description: "Show Raw Markdown")
                ShortcutRow(keys: "⌘ =", description: "Zoom In")
                ShortcutRow(keys: "⌘ -", description: "Zoom Out")
                ShortcutRow(keys: "⌘ 0", description: "Reset Zoom")
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 320, height: 400)
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
