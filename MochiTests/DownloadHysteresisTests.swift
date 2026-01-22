import XCTest
@testable import MochiCore

final class DownloadHysteresisTests: XCTestCase {
    func testEntersAfterSustainedHigh() {
        var h = DownloadHysteresis(enterRate: 100, exitRate: 50, enterSeconds: 2, exitSeconds: 2)
        XCTAssertFalse(h.update(rate: 0, dt: 1))
        XCTAssertFalse(h.update(rate: 120, dt: 1)) // 1s high
        XCTAssertTrue(h.update(rate: 130, dt: 1))  // 2s high => enter
    }

    func testExitsAfterSustainedLow() {
        var h = DownloadHysteresis(enterRate: 100, exitRate: 50, enterSeconds: 1, exitSeconds: 1)
        _ = h.update(rate: 200, dt: 1) // enter
        _ = h.update(rate: 200, dt: 0.1)
        XCTAssertTrue(h.update(rate: 40, dt: 0.5)) // not yet exit
        XCTAssertFalse(h.update(rate: 40, dt: 0.6)) // exit after hold
    }
}
