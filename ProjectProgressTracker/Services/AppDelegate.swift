import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app as regular app (shows dock icon + app menu bar)
        NSApp.setActivationPolicy(.regular)

        // Setup menu bar as soon as the app finishes launching
        MenuBarController.shared.setupMenuBar()
    }
}