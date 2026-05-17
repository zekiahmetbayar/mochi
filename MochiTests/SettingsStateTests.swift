import XCTest
@testable import MochiCore

final class SettingsStateTests: XCTestCase {
    func testDefaultSettingsAreInteractive() {
        let state = SettingsState()

        XCTAssertFalse(state.pinToMenuGap)
        XCTAssertFalse(state.startAtLogin)
    }
}
