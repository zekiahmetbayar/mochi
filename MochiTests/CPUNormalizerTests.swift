import XCTest
@testable import MochiCore

final class CPUNormalizerTests: XCTestCase {
    func testPercentCalculatesActiveOverTotal() {
        // prev ticks
        let prev: [UInt32] = [100, 20, 30, 200] // user, nice, sys, idle
        let curr: [UInt32] = [150, 25, 45, 225]
        let percent = CPUNormalizer.percent(previous: prev, current: curr)
        // deltas: user 50, nice 5, sys 15, idle 25 -> total 95, active 70 -> 73.68%
        XCTAssertEqual(percent.map { round($0 * 100) / 100 }, 73.68)
    }

    func testPercentNilWhenTotalZero() {
        let prev: [UInt32] = [0, 0, 0, 0]
        let curr: [UInt32] = [0, 0, 0, 0]
        XCTAssertNil(CPUNormalizer.percent(previous: prev, current: curr))
    }
}
