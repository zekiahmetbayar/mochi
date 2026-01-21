#if os(macOS)
import AppKit
import SwiftUI
import MochiCore

/// Borderless transparent overlay that sits above the menu bar.
final class OverlayWindowController: NSWindowController, OverlayControlling {
    private let menuBarHeight: CGFloat
    private let petHeight: CGFloat
    private let petOverlap: CGFloat

    init(
        contentView: some View,
        screen: NSScreen? = NSScreen.main,
        petHeight: CGFloat = 160,
        petOverlap: CGFloat = 12
    ) {
        self.menuBarHeight = NSStatusBar.system.thickness
        self.petHeight = petHeight
        self.petOverlap = petOverlap

        let screen = screen ?? NSScreen.main ?? NSScreen.screens.first!
        let frame = OverlayWindowController.makeFrame(
            screen: screen,
            menuBarHeight: self.menuBarHeight,
            petHeight: petHeight,
            petOverlap: petOverlap
        )

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true,
            screen: screen
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false

        let hosting = NSHostingView(rootView: AnyView(contentView))
        hosting.frame = panel.contentView?.bounds ?? frame
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func show() {
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private static func makeFrame(
        screen: NSScreen,
        menuBarHeight: CGFloat,
        petHeight: CGFloat,
        petOverlap: CGFloat
    ) -> NSRect {
        let geometry = OverlayGeometry.computeFrame(
            screenWidth: Double(screen.frame.width),
            screenHeight: Double(screen.frame.height),
            menuBarHeight: Double(menuBarHeight),
            petHeight: Double(petHeight),
            petOverlap: Double(petOverlap)
        )
        return NSRect(
            x: geometry.x,
            y: geometry.y,
            width: geometry.width,
            height: geometry.height
        )
    }
}
#endif
