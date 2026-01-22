import XCTest
@testable import MochiCore

final class SettingsStoreTests: XCTestCase {
    func testPersistsAndLoadsValues() {
        let suite = "mochi.settings.test"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = UserDefaultsSettingsStore(defaults: defaults)

        let original = SettingsState(
            clickThrough: true,
            startAtLogin: true,
            scale: 1.5,
            cpuThreshold: 80,
            ramThreshold: 82,
            downloadThreshold: 180_000,
            showDebugOverlay: true
        )
        store.save(original)

        let loaded = store.load()
        XCTAssertEqual(loaded, original)
    }
}
