import XCTest
@testable import MochiCore

final class MenuBarScreenSelectorTests: XCTestCase {
    func testPicksLargestTopInset() {
        let a = ScreenSnapshot(
            frame: ScreenRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: ScreenRect(x: 0, y: 23, width: 1920, height: 1057) // inset 23
        )
        let b = ScreenSnapshot(
            frame: ScreenRect(x: 1920, y: 0, width: 1920, height: 1080),
            visibleFrame: ScreenRect(x: 1920, y: 0, width: 1920, height: 1080) // inset 0
        )
        let selected = MenuBarScreenSelector.selectMenuBarScreen(from: [a, b])
        XCTAssertEqual(selected, a)
    }

    func testReturnsNilForEmpty() {
        XCTAssertNil(MenuBarScreenSelector.selectMenuBarScreen(from: []))
    }
}
