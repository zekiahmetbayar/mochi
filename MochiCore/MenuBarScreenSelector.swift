import Foundation

public struct ScreenSnapshot: Equatable {
    public let frame: CGRect
    public let visibleFrame: CGRect

    public init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    /// Heuristic menu bar height (frame top inset minus visible frame top).
    public var menuBarInset: CGFloat {
        (frame.origin.y + frame.height) - (visibleFrame.origin.y + visibleFrame.height)
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
