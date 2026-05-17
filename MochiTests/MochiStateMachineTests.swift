import XCTest
@testable import MochiCore

final class MochiStateMachineTests: XCTestCase {
    func testSleepRequiresSustainedOffline() {
        let sm = MochiStateMachine()
        var mood = MochiMood.normal
        var state = sm.update(stats: onlineStats(), dt: 1)
        mood = state.mood
        XCTAssertEqual(mood, .normal)

        // 2 seconds offline triggers sleep
        state = sm.update(stats: offlineStats(), dt: 1)
        state = sm.update(stats: offlineStats(), dt: 1)
        XCTAssertEqual(state.mood, .sleeping)

        // 1 second back online exits sleep
        state = sm.update(stats: onlineStats(), dt: 1.1)
        XCTAssertEqual(state.mood, .normal)
    }

    func testBagNeedsThroughputForThreeSeconds() {
        let sm = MochiStateMachine()
        var state = sm.update(stats: throughput(2_500_000), dt: 1)
        XCTAssertEqual(state.mood, .normal)
        state = sm.update(stats: throughput(2_500_000), dt: 1)
        state = sm.update(stats: throughput(2_500_000), dt: 1.2)
        XCTAssertEqual(state.mood, .carrying) // after ~3.2s above threshold
    }

    func testSweatUsesCpuHotOrPercent() {
        let sm = MochiStateMachine()
        // Not enough duration yet
        var state = sm.update(stats: cpu(75), dt: 2)
        XCTAssertNotEqual(state.mood, .sweating)
        // Reach duration
        state = sm.update(stats: cpu(75), dt: 6.1)
        XCTAssertEqual(state.mood, .sweating)
        // Drop CPU and exit after exitSeconds
        state = sm.update(stats: cpu(50), dt: 2)
        XCTAssertEqual(state.mood, .sweating)
        state = sm.update(stats: cpu(50), dt: 2.1)
        XCTAssertNotEqual(state.mood, .sweating)
    }

    func testChonkSlowsDown() {
        let sm = MochiStateMachine()
        var state = sm.update(stats: ram(80), dt: 5)
        state = sm.update(stats: ram(80), dt: 5.5) // exceed 10s
        XCTAssertEqual(state.mood, .chonky)
        XCTAssertLessThan(state.speedMultiplier, 1.0)
    }

    func testPriorityOrdering() {
        let sm = MochiStateMachine()
        // All conditions true; sleep should win.
        let stats = SystemStats(
            cpuPercent: 90,
            cpuHot: true,
            ramUsedPercent: 90,
            networkReachable: false,
            downloadRate: 200_000,
            downloadHeavy: true
        )
        let state = sm.update(stats: stats, dt: 3)
        XCTAssertEqual(state.mood, .sleeping)
    }

    func testAntiFlickerIgnoresShortBursts() {
        let sm = MochiStateMachine()
        // Alternating high/low bursts shorter than enter window should not trigger bag.
        var state = sm.update(stats: throughput(2_500_000), dt: 0.4)
        XCTAssertEqual(state.mood, .normal)
        state = sm.update(stats: throughput(0), dt: 0.4)
        XCTAssertEqual(state.mood, .normal)
        state = sm.update(stats: throughput(2_500_000), dt: 0.4)
        XCTAssertEqual(state.mood, .normal)
        state = sm.update(stats: throughput(0), dt: 0.4)
        XCTAssertEqual(state.mood, .normal)

        // Sustained high for ~3s should enter bag mode.
        state = sm.update(stats: throughput(2_500_000), dt: 1.0)
        state = sm.update(stats: throughput(2_500_000), dt: 1.0)
        state = sm.update(stats: throughput(2_500_000), dt: 1.0)
        XCTAssertEqual(state.mood, .carrying)
    }
}

// MARK: - Helpers

private func onlineStats() -> SystemStats {
    SystemStats(cpuPercent: 10, cpuHot: false, ramUsedPercent: 30, networkReachable: true, downloadRate: 0, downloadHeavy: false)
}

private func offlineStats() -> SystemStats {
    SystemStats(cpuPercent: 10, cpuHot: false, ramUsedPercent: 30, networkReachable: false, downloadRate: 0, downloadHeavy: false)
}

private func throughput(_ rate: Double) -> SystemStats {
    SystemStats(cpuPercent: 10, cpuHot: false, ramUsedPercent: 30, networkReachable: true, downloadRate: rate, downloadHeavy: false)
}

private func cpu(_ percent: Double) -> SystemStats {
    SystemStats(cpuPercent: percent, cpuHot: false, ramUsedPercent: 30, networkReachable: true, downloadRate: 0, downloadHeavy: false)
}

private func ram(_ percent: Double) -> SystemStats {
    SystemStats(cpuPercent: 10, cpuHot: false, ramUsedPercent: percent, networkReachable: true, downloadRate: 0, downloadHeavy: false)
}
