import XCTest
@testable import MochiCore

final class SettingsStateTests: XCTestCase {
    func testToggleClickThrough() {
        var state = SettingsState(clickThrough: false)
        state.toggleClickThrough()
        XCTAssertTrue(state.clickThrough)
        state.toggleClickThrough()
        XCTAssertFalse(state.clickThrough)
    }
}
