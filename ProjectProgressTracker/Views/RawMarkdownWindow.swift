//
//  RawMarkdownWindow.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct RawMarkdownWindow: View {
    let filename: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Raw Markdown: \(filename)")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            // Content
            ScrollView {
                Text(content)
                    .font(.body.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    RawMarkdownWindow(
        filename: "Example.md",
        content: "# Header\n\n- [ ] Task 1\n- [x] Task 2\n\nSome text content here."
    )
}
