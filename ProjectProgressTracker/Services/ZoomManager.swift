import Foundation
import SwiftUI

class ZoomManager: ObservableObject {
    @Published var scale: CGFloat {
        didSet {
            UserDefaults.standard.set(scale, forKey: "ZoomScale")
        }
    }

    let allowedScales: [CGFloat] = [0.85, 0.92, 1.0, 1.12, 1.28] // A-, Normal, A+, etc.
    init() {
        let stored = UserDefaults.standard.object(forKey: "ZoomScale") as? CGFloat
        let candidateScale = stored ?? 1.0
        // Validate that the scale is in allowedScales to prevent crashes
        self.scale = allowedScales.contains(candidateScale) ? candidateScale : 1.0
    }
    func smaller() {
        if let idx = allowedScales.firstIndex(of: scale), idx > 0 {
            scale = allowedScales[idx - 1]
        }
    }
    func bigger() {
        if let idx = allowedScales.firstIndex(of: scale), idx < (allowedScales.count-1) {
            scale = allowedScales[idx + 1]
        }
    }
    func reset() { scale = 1.0 }
}