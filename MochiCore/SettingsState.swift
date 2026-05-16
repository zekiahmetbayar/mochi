import Foundation

public enum PetKind: String, CaseIterable, Equatable, Codable {
    case cat, dog

    /// Filename prefix used for this pet's sprite assets.
    public var spritePrefix: String {
        switch self {
        case .cat: return "mochi"
        case .dog: return "dog"
        }
    }

    public var displayName: String {
        switch self {
        case .cat: return "Cat"
        case .dog: return "Dog"
        }
    }
}

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
    public var petKind: PetKind

    public init(
        clickThrough: Bool = false,
        pinToMenuGap: Bool = false,
        startAtLogin: Bool = false,
        scale: Double = 1.0,
        cpuThreshold: Double = 70.0,
        ramThreshold: Double = 75.0,
        downloadThreshold: Double = 100_000,
        showDebugOverlay: Bool = false,
        petKind: PetKind = .cat
    ) {
        self.clickThrough = clickThrough
        self.pinToMenuGap = pinToMenuGap
        self.startAtLogin = startAtLogin
        self.scale = scale
        self.cpuThreshold = cpuThreshold
        self.ramThreshold = ramThreshold
        self.downloadThreshold = downloadThreshold
        self.showDebugOverlay = showDebugOverlay
        self.petKind = petKind
    }

    public mutating func toggleClickThrough() {
        clickThrough.toggle()
    }
}
