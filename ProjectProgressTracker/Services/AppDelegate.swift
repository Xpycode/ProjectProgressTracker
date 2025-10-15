import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: applicationDidFinishLaunching")
        
        // Setup menu bar as soon as the app finishes launching
        MenuBarController.shared.setupMenuBar()
    }
}