import SwiftUI
import AppKit

class FloatingPanelController: NSObject, NSWindowDelegate {
    static let shared = FloatingPanelController()
    private var panel: NSPanel?
    private var hostingController: NSHostingController<AnyView>?

    func show<Content: View>(content: Content, anchorPoint: CGPoint, preferredWidth: CGFloat = 440, preferredHeight: CGFloat = 400) {
        if panel == nil {
            let mask: NSWindow.StyleMask = [
                .titled, .nonactivatingPanel, .closable, .fullSizeContentView
            ]
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: preferredWidth, height: preferredHeight),
                styleMask: mask,
                backing: .buffered, defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.hidesOnDeactivate = false
            panel.isOpaque = false
            panel.hasShadow = true
            panel.collectionBehavior = [.moveToActiveSpace, .transient]
            panel.titleVisibility = .hidden
            self.panel = panel
            panel.delegate = self
        }
        
        // Get visible screen area for proper placement
        // Try main screen first, fall back to first available screen
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            print("ERROR: Could not get any available screen.")
            // Fallback to default positioning if no screen is available
            panel?.setFrame(
                NSRect(x: 100, y: 100, width: preferredWidth, height: preferredHeight),
                display: true
            )
            panel?.contentViewController = NSHostingController(rootView: AnyView(content))
            panel?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let visibleFrame = screen.visibleFrame
        let width = preferredWidth
        let height = preferredHeight

        // Calculate best x, y based on anchorPoint (typically, menu bar icon center)
        let idealX = min(
            max(anchorPoint.x - width / 2, visibleFrame.minX),
            visibleFrame.maxX - width
        )
        let idealY: CGFloat = anchorPoint.y - height - 8 // drop below menu bar

        panel?.setFrame(
            NSRect(x: idealX, y: max(idealY, visibleFrame.minY + 30), width: width, height: height),
            display: true
        )

        // Embed SwiftUI content
        panel?.contentViewController = NSHostingController(rootView: AnyView(content))

        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        panel?.close()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        close()
    }
}