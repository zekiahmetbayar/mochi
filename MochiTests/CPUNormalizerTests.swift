import XCTest
@testable import MochiCore

final class CPUNormalizerTests: XCTestCase {
    func testPercentCalculatesActiveOverTotal() {
        var prev = Array(repeating: UInt32(0), count: Int(CPU_STATE_MAX))
        var curr = Array(repeating: UInt32(0), count: Int(CPU_STATE_MAX))
        prev[Int(CPU_STATE_USER)] = 100
        prev[Int(CPU_STATE_NICE)] = 20
        prev[Int(CPU_STATE_SYSTEM)] = 30
        prev[Int(CPU_STATE_IDLE)] = 200
        curr[Int(CPU_STATE_USER)] = 150
        curr[Int(CPU_STATE_NICE)] = 25
        curr[Int(CPU_STATE_SYSTEM)] = 45
        curr[Int(CPU_STATE_IDLE)] = 225
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
