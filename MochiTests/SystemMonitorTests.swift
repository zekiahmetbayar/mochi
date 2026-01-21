import XCTest
@testable import MochiCore

final class SystemMonitorTests: XCTestCase {
    func testPollOncePublishesFromProvidersOnMain() {
        let monitor = SystemMonitor(
            cpuProvider: MockCPU(values: [10]),
            memoryProvider: MockMemory(values: [55]),
            networkProvider: MockNetwork(values: [true]),
            downloadProvider: MockDownload(values: [1234]),
            pollInterval: 1.0,
            queue: DispatchQueue(label: "test.monitor")
        )

        let expectation = expectation(description: "stats updated")
        monitor.onUpdate = { stats in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(stats.cpuPercent, 10)
            XCTAssertEqual(stats.ramUsedPercent, 55)
            XCTAssertEqual(stats.networkReachable, true)
            XCTAssertEqual(stats.downloadRate, 1234)
            expectation.fulfill()
        }

        monitor.pollOnce()
        wait(for: [expectation], timeout: 1.0)
    }

    func testPollOnceClampsAndPersistsWhenNil() {
        let monitor = SystemMonitor(
            cpuProvider: MockCPU(values: [120, nil]),
            memoryProvider: MockMemory(values: [-5, nil]),
            networkProvider: MockNetwork(values: [false, true]),
            downloadProvider: MockDownload(values: [-10, nil]),
            pollInterval: 1.0,
            queue: DispatchQueue(label: "test.monitor")
        )

        let first = expectation(description: "first update")
        monitor.onUpdate = { stats in
            if stats.cpuPercent == 100 {
                XCTAssertEqual(stats.ramUsedPercent, 0)
                XCTAssertEqual(stats.networkReachable, false)
                XCTAssertEqual(stats.downloadRate, 0)
                first.fulfill()
            }
        }
        monitor.pollOnce()
        wait(for: [first], timeout: 1.0)

        let second = expectation(description: "second update uses previous on nil")
        monitor.onUpdate = { stats in
            XCTAssertEqual(stats.cpuPercent, 100) // clamped previous value
            XCTAssertEqual(stats.ramUsedPercent, 0) // clamped previous value
            XCTAssertEqual(stats.networkReachable, true)
            XCTAssertEqual(stats.downloadRate, 0) // stays non-negative
            second.fulfill()
        }
        monitor.pollOnce()
        wait(for: [second], timeout: 1.0)
    }
}

// MARK: - Mocks

private final class MockCPU: CPUProviding {
    private var values: [Double?]
    init(values: [Double?]) { self.values = values }
    func cpuPercent() -> Double? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }
}

private final class MockMemory: MemoryProviding {
    private var values: [Double?]
    init(values: [Double?]) { self.values = values }
    func ramUsedPercent() -> Double? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }
}

private final class MockNetwork: NetworkProviding {
    private var values: [Bool]
    init(values: [Bool]) { self.values = values }
    func isReachable() -> Bool {
        guard !values.isEmpty else { return true }
        return values.removeFirst()
    }
}

private final class MockDownload: DownloadProviding {
    private var values: [Double?]
    init(values: [Double?]) { self.values = values }
    func downloadRate() -> Double? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }
}
