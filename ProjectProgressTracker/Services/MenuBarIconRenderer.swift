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
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)

            // Draw the base icon (unfilled) with a lower opacity.
            // For template images, we don't need to set a color; drawing with
            // black and using the fraction parameter for alpha is sufficient.
            if let baseIcon = NSImage(systemSymbolName: "list.bullet.clipboard", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
                baseIcon.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.4)
            }

            // Draw the filled portion on top, clipped to the completion percentage.
            if completionPercentage > 0 {
                if let filledIcon = NSImage(systemSymbolName: "list.bullet.clipboard.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
                    let fillHeight = rect.height * (completionPercentage / 100.0)
                    let fillRect = NSRect(x: 0, y: 0, width: rect.width, height: fillHeight)

                    NSGraphicsContext.current?.saveGraphicsState()
                    NSBezierPath(rect: fillRect).addClip()
                    
                    // Draw the filled part with full opacity. The .sourceOver operation
                    // will draw this on top of the base icon.
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