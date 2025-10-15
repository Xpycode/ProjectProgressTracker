//
//  Notifications.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 11.10.25.
//

import Foundation

extension Notification.Name {
    static let spacebarPressed = Notification.Name("spacebarPressed")
    static let openFile = Notification.Name("openFile")
    static let showRawMarkdown = Notification.Name("showRawMarkdown")
    static let navigateToNextHeader = Notification.Name("navigateToNextHeader")
    static let navigateToPreviousHeader = Notification.Name("navigateToPreviousHeader")
    static let navigateToNextSubHeader = Notification.Name("navigateToNextSubHeader")
    static let navigateToPreviousSubHeader = Notification.Name("navigateToPreviousSubHeader")
    static let navigateToNextBoldCheckbox = Notification.Name("navigateToNextBoldCheckbox")
    static let navigateToPreviousBoldCheckbox = Notification.Name("navigateToPreviousBoldCheckbox")
}