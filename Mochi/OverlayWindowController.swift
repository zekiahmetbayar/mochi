#if os(macOS)
import AppKit
import CoreGraphics
import SwiftUI
import MochiCore

/// Borderless transparent overlay that sits above the menu bar.
final class OverlayWindowController: NSWindowController, OverlayControlling {
    private let menuBarHeight: CGFloat
    private let petHeight: CGFloat
    private let petOverlap: CGFloat
    private let playAreaWidth: CGFloat?
    private let screen: NSScreen

    init(
        contentView: some View,
        screen: NSScreen? = NSScreen.main,
        petHeight: CGFloat = 160,
        petOverlap: CGFloat = 12,
        playAreaWidth: CGFloat? = nil
    ) {
        self.menuBarHeight = NSStatusBar.system.thickness
        self.petHeight = petHeight
        self.petOverlap = petOverlap
        self.playAreaWidth = playAreaWidth
        self.screen = screen ?? NSScreen.main ?? NSScreen.screens.first!

        let frame = OverlayWindowController.makeFrame(
            screen: self.screen,
            menuBarHeight: self.menuBarHeight,
            petHeight: petHeight,
            petOverlap: petOverlap,
            playAreaWidth: playAreaWidth
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

    /// Returns the notch X range in screen-local coordinates (relative to screen.minX),
    /// or nil if the current screen has no notch.
    func notchLocalRange() -> (left: Double, right: Double)? {
        if #available(macOS 12.0, *) {
            guard let left = screen.auxiliaryTopLeftArea,
                  let right = screen.auxiliaryTopRightArea else { return nil }
            let notchLeft = left.maxX - screen.frame.minX
            let notchRight = right.minX - screen.frame.minX
            guard notchRight > notchLeft else { return nil }
            return (Double(notchLeft), Double(notchRight))
        }
        return nil
    }

    var overlayWidth: Double {
        Double(window?.frame.width ?? (playAreaWidth ?? 0))
    }

    var screenWidth: Double {
        Double(screen.frame.width)
    }

    func move(toX x: Double) {
        guard let window else { return }
        let minX = screen.frame.minX
        let maxX = screen.frame.maxX - window.frame.width
        let clampedX = max(minX, min(minX + CGFloat(x), maxX))
        window.setFrameOrigin(NSPoint(x: clampedX, y: window.frame.origin.y))
    }

    /// Finds the first gap to the left of right-side menu bar status items.
    /// Returns local screen X coordinates, matching `move(toX:)` input.
    func resolvePreferredPinnedX(completion: @escaping (Double?) -> Void) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.resolvePreferredPinnedX(completion: completion) ?? completion(nil)
            }
            return
        }

        leftEdgeUsingStatusProbe { [weak self] probeEdge in
            guard let self else {
                completion(nil)
                return
            }
            let leftEdge = probeEdge ?? self.leftEdgeOfRightStatusItems()
            completion(leftEdge.map(self.localPinnedX(fromLeftEdge:)))
        }
    }

    private func localPinnedX(fromLeftEdge leftEdge: CGFloat) -> Double {
        let windowWidth = window?.frame.width ?? (playAreaWidth ?? petHeight * 2)
        let globalX = leftEdge - windowWidth - 6
        let localX = globalX - screen.frame.minX
        let maxLocal = max(0, screen.frame.width - windowWidth)
        return Double(min(max(localX, 0), maxLocal))
    }

    private func leftEdgeUsingStatusProbe(completion: @escaping (CGFloat?) -> Void) {
        let statusBar = NSStatusBar.system
        let probe = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = probe.button else {
            statusBar.removeStatusItem(probe)
            completion(nil)
            return
        }

        button.title = ""
        button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.alphaValue = 0.015
        button.isEnabled = true

        let topBandMinY = screen.frame.maxY - menuBarHeight - 10
        let topBandMaxY = screen.frame.maxY + 2
        let rightBandMinX = screen.frame.maxX - max(420, screen.frame.width * 0.45)
        let minHeight = max(menuBarHeight - 8, 18)
        let retries = 10
        let retryDelay = 0.05

        func finish(_ edge: CGFloat?) {
            statusBar.removeStatusItem(probe)
            completion(edge)
        }

        func poll(remaining: Int) {
            if let probeWindow = button.window {
                let frame = probeWindow.frame
                let validSize = frame.width >= 20 && frame.height >= minHeight
                let validTopBand = frame.maxY >= topBandMinY && frame.minY <= topBandMaxY
                let validRightBand = frame.minX >= rightBandMinX && frame.maxX <= screen.frame.maxX + 2
                if validSize && validTopBand && validRightBand {
                    // Use minX so Mochi lands in the first free gap left of status items.
                    finish(frame.minX)
                    return
                }
            }

            if remaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                    poll(remaining: remaining - 1)
                }
            } else {
                finish(nil)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            poll(remaining: retries)
        }
    }

    private func leftEdgeOfRightStatusItems() -> CGFloat? {
        guard let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let rightEdge = screen.frame.maxX
        let topBandMinY = screen.frame.maxY - menuBarHeight - 6
        let topBandMaxY = screen.frame.maxY + 2
        let rightBandMinX = rightEdge - max(420, screen.frame.width * 0.45)

        var leftmost: CGFloat?
        for info in infos {
            if let owner = info[kCGWindowOwnerName as String] as? String, owner == "Mochi" {
                continue
            }
            guard let boundsValue = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsValue as CFDictionary) else { continue }
            if bounds.width < 8 || bounds.height < 8 || bounds.width > 420 || bounds.height > 80 {
                continue
            }
            let intersectsTopBand = bounds.maxY >= topBandMinY && bounds.minY <= topBandMaxY
            let touchesRightBand = bounds.minX >= rightBandMinX && bounds.maxX <= rightEdge + 2
            if !intersectsTopBand || !touchesRightBand {
                continue
            }
            leftmost = min(leftmost ?? bounds.minX, bounds.minX)
        }
        return leftmost
    }

    private static func makeFrame(
        screen: NSScreen,
        menuBarHeight: CGFloat,
        petHeight: CGFloat,
        petOverlap: CGFloat,
        playAreaWidth: CGFloat?
    ) -> NSRect {
        let geometry = OverlayGeometry.computeFrame(
            screenWidth: Double(screen.frame.width),
            screenHeight: Double(screen.frame.height),
            menuBarHeight: Double(menuBarHeight),
            petHeight: Double(petHeight),
            petOverlap: Double(petOverlap),
            overlayWidth: playAreaWidth.map(Double.init)
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
