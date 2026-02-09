import Foundation

/// Pure logic settings state for testability.
public struct SettingsState: Equatable {
    public var clickThrough: Bool
    public var pinToMenuGap: Bool
    public var startAtLogin: Bool
    public var scale: Double
    public var cpuThreshold: Double
    public var ramThreshold: Double
    public var downloadThreshold: Double
    public var showDebugOverlay: Bool

    public init(
        clickThrough: Bool = false,
        pinToMenuGap: Bool = false,
        startAtLogin: Bool = false,
        scale: Double = 1.0,
        cpuThreshold: Double = 70.0,
        ramThreshold: Double = 75.0,
        downloadThreshold: Double = 100_000,
        showDebugOverlay: Bool = false
    ) {
        self.clickThrough = clickThrough
        self.pinToMenuGap = pinToMenuGap
        self.startAtLogin = startAtLogin
        self.scale = scale
        self.cpuThreshold = cpuThreshold
        self.ramThreshold = ramThreshold
        self.downloadThreshold = downloadThreshold
        self.showDebugOverlay = showDebugOverlay
    }

    public mutating func toggleClickThrough() {
        clickThrough.toggle()
    }
}
