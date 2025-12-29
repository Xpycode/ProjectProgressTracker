//
//  MenuBarIconRenderer.swift
//  ProjectProgressTracker
//
//  Created by Claude on 08.10.25.
//

import AppKit
import SwiftUI

/// Renders the menu bar icon with a progressive fill effect based on project completion.
/// The icon fills from bottom to top as completion percentage increases.
class MenuBarIconRenderer {

    /// Standard size for menu bar icons
    private static let iconSize = NSSize(width: 22, height: 22)

    /// Point size for the SF Symbol
    private static let symbolPointSize: CGFloat = 18

    /// Opacity for the unfilled base icon
    private static let baseIconOpacity: CGFloat = 0.4

    /// Creates a menu bar icon that visually represents the completion percentage.
    /// - Parameter completionPercentage: A value from 0 to 100 representing progress.
    /// - Returns: An NSImage configured as a template image for the menu bar.
    static func createIcon(completionPercentage: Double) -> NSImage {
        let image = NSImage(size: iconSize, flipped: false) { rect in
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .medium)

            // Draw the base icon (unfilled) with lower opacity as the background
            if let baseIcon = NSImage(systemSymbolName: "list.bullet.clipboard", accessibilityDescription: "Project Progress")?.withSymbolConfiguration(symbolConfig) {
                baseIcon.draw(in: rect, from: .zero, operation: .sourceOver, fraction: baseIconOpacity)
            }

            // Draw the filled portion on top, clipped to the completion percentage
            if completionPercentage > 0 {
                if let filledIcon = NSImage(systemSymbolName: "list.bullet.clipboard.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
                    // Calculate fill height from bottom to top
                    let fillHeight = rect.height * (completionPercentage / 100.0)
                    let fillRect = NSRect(x: 0, y: 0, width: rect.width, height: fillHeight)

                    NSGraphicsContext.current?.saveGraphicsState()
                    NSBezierPath(rect: fillRect).addClip()

                    // Draw the filled part with full opacity on top of the base icon
                    filledIcon.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

                    NSGraphicsContext.current?.restoreGraphicsState()
                }
            }

            return true
        }

        image.isTemplate = true
        return image
    }
}
