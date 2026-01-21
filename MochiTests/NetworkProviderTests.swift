import XCTest
@testable import MochiCore

final class NetworkProviderTests: XCTestCase {
    func testStubAlwaysReachable() {
        let provider = NetworkStub()
        XCTAssertTrue(provider.isReachable())
    }

    func testSystemMonitorRespectsMockReachability() {
        let monitor = SystemMonitor(
            cpuProvider: CPUStub(),
            memoryProvider: MemoryStub(),
            networkProvider: MockNetwork(values: [false, true]),
            downloadProvider: DownloadStub(),
            pollInterval: 1.0,
            queue: DispatchQueue(label: "test.net")
        )

        let first = expectation(description: "first reachability false")
        monitor.onUpdate = { (stats: SystemStats) in
            if stats.networkReachable == false {
                first.fulfill()
            }
        }
        monitor.pollOnce()
        wait(for: [first], timeout: 1.0)

        let second = expectation(description: "second reachability true")
        monitor.onUpdate = { (stats: SystemStats) in
            if stats.networkReachable == true {
                second.fulfill()
            }
        }
        monitor.pollOnce()
        wait(for: [second], timeout: 1.0)
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
