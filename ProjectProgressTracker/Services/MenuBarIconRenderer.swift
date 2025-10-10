//
//  MenuBarIconRenderer.swift
//  ProjectProgressTracker
//
//  Created by Claude on 08.10.25.
//

import AppKit
import SwiftUI

class MenuBarIconRenderer {
    static func createIcon(completionPercentage: Double) -> NSImage {
        let size = NSSize(width: 20, height: 20)

        let image = NSImage(size: size, flipped: false) { rect in
            // Calculate fill height
            let fillHeight = rect.height * (completionPercentage / 100.0)

            // Get SF Symbol
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)

            // Draw background (unfilled) icon in light gray
            if let baseIcon = NSImage(systemSymbolName: "list.bullet.clipboard", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
                NSGraphicsContext.current?.saveGraphicsState()
                NSColor.black.withAlphaComponent(0.3).set()
                baseIcon.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
                NSGraphicsContext.current?.restoreGraphicsState()
            }

            // Draw filled portion with clipping
            if let filledIcon = NSImage(systemSymbolName: "list.bullet.clipboard.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
                NSGraphicsContext.current?.saveGraphicsState()

                // Clip to bottom portion
                let fillRect = NSRect(x: 0, y: 0, width: rect.width, height: fillHeight)
                NSBezierPath(rect: fillRect).addClip()

                NSColor.black.set()
                filledIcon.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

                NSGraphicsContext.current?.restoreGraphicsState()
            }

            return true
        }

        image.isTemplate = true // Use template mode for automatic dark/light mode adaptation
        return image
    }
}
