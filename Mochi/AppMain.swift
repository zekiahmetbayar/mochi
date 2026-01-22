#if os(macOS)
import SwiftUI
import MochiCore

@main
struct MochiApp: App {
    @NSApplicationDelegateAdaptor(OverlayAppDelegate.self) var appDelegate
    @StateObject private var overlayBridge = OverlayBridge.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class OverlayAppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private let lifecycle = OverlayLifecycle()
    weak var overlayBridge: OverlayBridge? = OverlayBridge.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusHeight = NSStatusBar.system.thickness
        let spriteHeight = max(min(statusHeight - 2, 26), 18)
        let spriteWidth = spriteHeight * 2 // keep 2:1 aspect
        let petHeight = spriteHeight
        let petOverlap: CGFloat = petHeight // clamp overlay height to menu bar height

        let content = ContentView(playAreaWidth: spriteWidth).environmentObject(OverlayBridge.shared)
        overlayController = OverlayWindowController(
            contentView: content,
            petHeight: petHeight,
            petOverlap: petOverlap,
            playAreaWidth: spriteWidth
        )
        if let overlayController {
            lifecycle.setController(overlayController)
            overlayBridge?.controller = overlayController
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
