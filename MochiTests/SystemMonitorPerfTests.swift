import XCTest
@testable import MochiCore

final class SystemMonitorPerfTests: XCTestCase {
    func testSkipsPublishWhenChangeBelowThreshold() {
        let monitor = SystemMonitor(
            cpuProvider: ConstantCPU(value: 10),
            memoryProvider: ConstantMemory(value: 20),
            networkProvider: ConstantNetwork(value: true),
            downloadProvider: ConstantDownload(value: 1_000),
            pollInterval: 1.0,
            queue: DispatchQueue(label: "perf.test")
        )

        let first = expectation(description: "first publish")
        monitor.onUpdate = { _ in first.fulfill() }
        monitor.pollOnce()
        wait(for: [first], timeout: 1.0)

        let second = expectation(description: "no publish on identical")
        second.isInverted = true
        monitor.onUpdate = { _ in second.fulfill() }
        monitor.pollOnce()
        wait(for: [second], timeout: 0.5)
    }
}

private struct ConstantCPU: CPUProviding {
    let value: Double
    func cpuPercent() -> Double? { value }
}

private struct ConstantMemory: MemoryProviding {
    let value: Double
    func ramUsedPercent() -> Double? { value }
}

private struct ConstantNetwork: NetworkProviding {
    let value: Bool
    func isReachable() -> Bool { value }
}

private struct ConstantDownload: DownloadProviding {
    let value: Double
    func downloadRate() -> Double? { value }
}
