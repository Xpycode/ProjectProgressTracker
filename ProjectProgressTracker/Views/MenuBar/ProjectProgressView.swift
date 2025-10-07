//
//  ProjectProgressView.swift
//  ProjectProgressTracker
//
//  Created by Alex on [[DATE]].
//

import SwiftUI

struct ProjectProgressView: View {
    @ObservedObject var project: Document
    @State private var showAllCheckboxes = false
    
    var body: some View {
        GeometryReader { geo in
            let screenWidth = NSScreen.main?.visibleFrame.width ?? geo.size.width
            let sideMargin: CGFloat = 32 // macOS menu bar margin safety
            let maxAllowedWidth: CGFloat = min(440, max(340, screenWidth * 0.8 - sideMargin))

            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.filename)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("\(Int(project.completionPercentage))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ProgressView(value: project.completionPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 60)
                }
                .padding(.horizontal)
                Divider()
                ContentListView(document: project)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(.bottom, 4)
            }
            .padding(.top, 6)
            .frame(
                minWidth: 320,
                idealWidth: maxAllowedWidth,
                maxWidth: maxAllowedWidth,
                minHeight: 300,
                maxHeight: 450
            )
        }
        .frame(height: 350) // fixes vertical overflow if needed
    }
}