import XCTest
@testable import MochiCore

final class CPULoadHysteresisTests: XCTestCase {
    func testEntersAfterSustainedHigh() {
        var hys = CPULoadHysteresis(enterPercent: 70, exitPercent: 60, enterSeconds: 4, exitSeconds: 2)
        var state = false
        // 4 seconds at 75% should flip to hot.
        for _ in 0..<4 {
            state = hys.update(percent: 75, dt: 1.0)
        }
        XCTAssertTrue(state)
    }

    func testStaysHotUntilCooldown() {
        var hys = CPULoadHysteresis(enterPercent: 70, exitPercent: 60, enterSeconds: 2, exitSeconds: 3)
        // Enter hot
        _ = hys.update(percent: 80, dt: 2.0)
        XCTAssertTrue(hys.update(percent: 80, dt: 0.1))
        // Brief dip above exit threshold should not clear immediately
        XCTAssertTrue(hys.update(percent: 65, dt: 1.0))
        XCTAssertTrue(hys.update(percent: 65, dt: 1.0))
        // Now stay below exit for long enough (total 3.1s <= exit threshold)
        XCTAssertTrue(hys.update(percent: 50, dt: 1.5))
        XCTAssertFalse(hys.update(percent: 50, dt: 1.6))
    }
}
