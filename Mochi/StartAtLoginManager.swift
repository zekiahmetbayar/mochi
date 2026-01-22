import Foundation
#if os(macOS)
import ServiceManagement
#endif
import MochiCore

final class StartAtLoginManager: StartAtLoginControlling {
    var isSupported: Bool {
        #if os(macOS)
        if #available(macOS 13, *) { return true } else { return false }
        #else
        return false
        #endif
    }

    var isEnabled: Bool {
        #if os(macOS)
        guard #available(macOS 13, *) else { return false }
        return SMAppService.mainApp.status == .enabled
        #else
        return false
        #endif
    }

    @discardableResult
    func setEnabled(_ enable: Bool) -> Bool {
        #if os(macOS)
        guard #available(macOS 13, *) else { return false }
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("StartAtLogin error: \(error)")
            return false
        }
        #else
        return false
        #endif
    }
}
