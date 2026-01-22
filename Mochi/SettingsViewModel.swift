#if os(macOS)
import Foundation
import SwiftUI
import MochiCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var state: SettingsState {
        didSet { save() }
    }

    private let store: SettingsPersisting

    init(store: SettingsPersisting = UserDefaultsSettingsStore()) {
        self.store = store
        self.state = store.load()
    }

    private func save() {
        store.save(state)
    }
}
#endif
