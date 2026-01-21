#if os(macOS)
import SwiftUI
import MochiCore

@main
struct MochiApp: App {
    @NSApplicationDelegateAdaptor(OverlayAppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class OverlayAppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private let lifecycle = OverlayLifecycle()

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayController = OverlayWindowController(
            contentView: ContentView(),
            petHeight: 220,
            petOverlap: 20
        )
        if let overlayController {
            lifecycle.setController(overlayController)
        }
        lifecycle.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycle.stop()
        overlayController = nil
    }
}
#else
import Foundation
import MochiCore

@main
struct MochiLauncher {
    static func main() {
        // Non-macOS placeholder keeps CI builds lightweight.
        print("Mochi bootstrap placeholder")
    }
}
#endif
