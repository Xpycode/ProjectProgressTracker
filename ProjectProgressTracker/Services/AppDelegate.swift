import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: applicationDidFinishLaunching")

        // Configure app as menu bar accessory (shows menu bar icon + can show windows when needed)
        NSApp.setActivationPolicy(.accessory)
        print("🚀 AppDelegate: Set activation policy to .accessory")

        // Setup menu bar as soon as the app finishes launching
        MenuBarController.shared.setupMenuBar()
    }
}