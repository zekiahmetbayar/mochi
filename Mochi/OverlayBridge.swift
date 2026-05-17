#if os(macOS)
import AppKit
import Combine

/// Bridges SwiftUI settings to the AppKit overlay window.
final class OverlayBridge: ObservableObject {
    static let shared = OverlayBridge()

    weak var controller: OverlayWindowController? {
        didSet { controller?.window?.ignoresMouseEvents = false }
    }

    func movePet(toX x: Double) {
        controller?.move(toX: x)
    }

    func notchLocalRange() -> (left: Double, right: Double)? {
        controller?.notchLocalRange()
    }

    var overlayWidth: Double { controller?.overlayWidth ?? 0 }

    func resolvePreferredPinnedX(completion: @escaping (Double?) -> Void) {
        guard let controller else {
            completion(nil)
            return
        }
        controller.resolvePreferredPinnedX(completion: completion)
    }

    func quitApp() {
        NSApp.terminate(nil)
    }
}
#endif
