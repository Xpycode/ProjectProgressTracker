//
//  MenuBarIconView.swift
//  ProjectProgressTracker
//
//  Created by Claude on 08.10.25.
//

import SwiftUI

struct MenuBarIconView: View {
    let completionPercentage: Double

    var body: some View {
        let icon = MenuBarIconRenderer.createIcon(completionPercentage: completionPercentage)
        icon.isTemplate = false // Force non-template rendering

        return Image(nsImage: icon)
            .renderingMode(.original) // Preserve original colors
    }
}

#Preview {
    HStack(spacing: 20) {
        MenuBarIconView(completionPercentage: 0)
        MenuBarIconView(completionPercentage: 25)
        MenuBarIconView(completionPercentage: 50)
        MenuBarIconView(completionPercentage: 75)
        MenuBarIconView(completionPercentage: 100)
    }
    .padding()
    .frame(width: 300, height: 100)
}
