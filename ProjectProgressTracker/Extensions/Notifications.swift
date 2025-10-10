import Foundation

extension Notification.Name {
    /// Notification to post when the user selects the "Open" menu item.
    static let openFile = Notification.Name("com.projectprogresstracker.openFile")
    /// Notification to show raw markdown content window.
    static let showRawMarkdown = Notification.Name("com.projectprogresstracker.showRawMarkdown")
}
