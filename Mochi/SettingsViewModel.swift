#if os(macOS)
import Foundation
import SwiftUI
import MochiCore

@MainActor
final class SettingsViewModel: ObservableObject {
    private var isApplyingStartAtLogin = false

    @Published var state: SettingsState {
        didSet {
            if !isApplyingStartAtLogin,
               state.startAtLogin != oldValue.startAtLogin {
                applyStartAtLogin(desired: state.startAtLogin, fallback: oldValue.startAtLogin)
            }
            save()
        }
    }

    let startAtLoginSupported: Bool

    private let store: SettingsPersisting
    private let loginCoordinator: StartAtLoginCoordinator?

    init(
        store: SettingsPersisting = UserDefaultsSettingsStore(),
        loginController: StartAtLoginControlling? = StartAtLoginManager()
    ) {
        self.store = store
        if let controller = loginController, controller.isSupported {
            self.loginCoordinator = StartAtLoginCoordinator(controller: controller)
            self.startAtLoginSupported = true
        } else {
            self.loginCoordinator = nil
            self.startAtLoginSupported = false
        }

        var loaded = store.load()
        if let coord = loginCoordinator {
            loaded.startAtLogin = coord.isEnabled
        }
        self.state = loaded
    }

    private func save() {
        store.save(state)
    }

    private func applyStartAtLogin(_ desired: Bool, fallback: Bool) {
        guard let coord = loginCoordinator else {
            isApplyingStartAtLogin = true
            state.startAtLogin = fallback
            isApplyingStartAtLogin = false
            return
        }
        let success = coord.apply(desired: desired)
        if !success {
            isApplyingStartAtLogin = true
            state.startAtLogin = fallback
            isApplyingStartAtLogin = false
        }
    }
}
#endif
