import Foundation

/// Pure logic settings state for testability.
public struct SettingsState: Equatable {
    public var clickThrough: Bool = false

    public init(clickThrough: Bool = false) {
        self.clickThrough = clickThrough
    }

    public mutating func toggleClickThrough() {
        clickThrough.toggle()
    }
}
