import Foundation

public protocol SettingsPersisting {
    func load() -> SettingsState
    func save(_ state: SettingsState)
}

public final class UserDefaultsSettingsStore: SettingsPersisting {
    private enum Key: String {
        case pinToMenuGap = "mochi.settings.pinToMenuGap"
        case startAtLogin = "mochi.settings.startAtLogin"
        case scale = "mochi.settings.scale"
        case cpuThreshold = "mochi.settings.cpuThreshold"
        case ramThreshold = "mochi.settings.ramThreshold"
        case downloadThreshold = "mochi.settings.downloadThreshold"
        case showDebugOverlay = "mochi.settings.showDebugOverlay"
        case petKind = "mochi.settings.petKind"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> SettingsState {
        var state = SettingsState()
        state.pinToMenuGap = defaults.bool(forKey: Key.pinToMenuGap.rawValue)
        state.startAtLogin = defaults.bool(forKey: Key.startAtLogin.rawValue)

        let storedScale = defaults.double(forKey: Key.scale.rawValue)
        if storedScale > 0 {
            state.scale = storedScale
        }

        let cpu = defaults.double(forKey: Key.cpuThreshold.rawValue)
        if cpu > 0 { state.cpuThreshold = cpu }

        let ram = defaults.double(forKey: Key.ramThreshold.rawValue)
        if ram > 0 { state.ramThreshold = ram }

        let dl = defaults.double(forKey: Key.downloadThreshold.rawValue)
        if dl > 0 { state.downloadThreshold = dl }

        state.showDebugOverlay = defaults.bool(forKey: Key.showDebugOverlay.rawValue)
        if let raw = defaults.string(forKey: Key.petKind.rawValue),
           let kind = PetKind(rawValue: raw) {
            state.petKind = kind
        }
        return state
    }

    public func save(_ state: SettingsState) {
        defaults.set(state.pinToMenuGap, forKey: Key.pinToMenuGap.rawValue)
        defaults.set(state.startAtLogin, forKey: Key.startAtLogin.rawValue)
        defaults.set(state.scale, forKey: Key.scale.rawValue)
        defaults.set(state.cpuThreshold, forKey: Key.cpuThreshold.rawValue)
        defaults.set(state.ramThreshold, forKey: Key.ramThreshold.rawValue)
        defaults.set(state.downloadThreshold, forKey: Key.downloadThreshold.rawValue)
        defaults.set(state.showDebugOverlay, forKey: Key.showDebugOverlay.rawValue)
        defaults.set(state.petKind.rawValue, forKey: Key.petKind.rawValue)
    }
}
