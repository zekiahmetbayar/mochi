public struct ScreenRect: Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxY: Double { y + height }
}

public struct ScreenSnapshot: Equatable {
    public let frame: ScreenRect
    public let visibleFrame: ScreenRect

    public init(frame: ScreenRect, visibleFrame: ScreenRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    /// Heuristic menu bar height (frame top inset minus visible frame top).
    public var menuBarInset: Double {
        frame.maxY - visibleFrame.maxY
    }
}

/// Picks the screen that likely hosts the menu bar by selecting the largest top inset.
public enum MenuBarScreenSelector {
    public static func selectMenuBarScreen(from screens: [ScreenSnapshot]) -> ScreenSnapshot? {
        guard !screens.isEmpty else { return nil }
        return screens.max { lhs, rhs in
            lhs.menuBarInset < rhs.menuBarInset
        }
    }
}
