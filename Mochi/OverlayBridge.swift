#if os(macOS)
import AppKit
import Combine

/// Bridges SwiftUI settings to the AppKit overlay window.
final class OverlayBridge: ObservableObject {
    static let shared = OverlayBridge()

    weak var controller: OverlayWindowController? {
        didSet { controller?.window?.ignoresMouseEvents = clickThrough }
    }

    @Published var clickThrough: Bool = false {
        didSet { controller?.window?.ignoresMouseEvents = clickThrough }
    }

    func movePet(toX x: Double) {
        controller?.move(toX: x)
    }

    func toggleClickThrough() {
        clickThrough.toggle()
    }

    func quitApp() {
        NSApp.terminate(nil)
    }
}
#endif
