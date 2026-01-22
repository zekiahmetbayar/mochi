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

    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildOverlay(on: currentMenuBarScreen())
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildOverlayForScreenChange()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycle.stop()
        overlayController = nil
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    private func rebuildOverlayForScreenChange() {
        lifecycle.stop()
        overlayController = nil
        buildOverlay(on: currentMenuBarScreen())
    }

    private func currentMenuBarScreen() -> NSScreen {
        let snapshots = NSScreen.screens.map { screen in
            ScreenSnapshot(
                frame: ScreenRect(x: screen.frame.origin.x,
                                  y: screen.frame.origin.y,
                                  width: screen.frame.size.width,
                                  height: screen.frame.size.height),
                visibleFrame: ScreenRect(x: screen.visibleFrame.origin.x,
                                         y: screen.visibleFrame.origin.y,
                                         width: screen.visibleFrame.size.width,
                                         height: screen.visibleFrame.size.height)
            )
        }
        if let selected = MenuBarScreenSelector.selectMenuBarScreen(from: snapshots),
           let match = NSScreen.screens.first(where: {
               screen in
               screen.frame.origin.x == selected.frame.x &&
               screen.frame.origin.y == selected.frame.y &&
               screen.frame.size.width == selected.frame.width &&
               screen.frame.size.height == selected.frame.height
           }) {
            return match
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }

    private func buildOverlay(on screen: NSScreen) {
        let statusHeight = NSStatusBar.system.thickness
        let spriteHeight = max(min(statusHeight - 2, 26), 18)
        let spriteWidth = spriteHeight * 2 // keep 2:1 aspect
        let petHeight = spriteHeight
        let petOverlap: CGFloat = petHeight // clamp overlay height to menu bar height

        let content = ContentView(playAreaWidth: spriteWidth).environmentObject(OverlayBridge.shared)
        overlayController = OverlayWindowController(
            contentView: content,
            screen: screen,
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
