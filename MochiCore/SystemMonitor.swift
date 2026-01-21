import Foundation
#if canImport(Combine)
import Combine
#else
public protocol ObservableObject {}
#endif

public protocol CPUProviding {
    /// Returns CPU usage percentage in range 0...100 (total normalized).
    func cpuPercent() -> Double?
}

public protocol MemoryProviding {
    /// Returns RAM usage percentage in range 0...100.
    func ramUsedPercent() -> Double?
}

public protocol NetworkProviding {
    /// Returns `true` when network is reachable.
    func isReachable() -> Bool
}

public protocol DownloadProviding {
    /// Returns current download rate in bytes per second.
    func downloadRate() -> Double?
}

public struct SystemStats: Equatable {
    public var cpuPercent: Double
    public var cpuTemp: Double?
    public var ramUsedPercent: Double
    public var networkReachable: Bool
    public var downloadRate: Double

    public init(
        cpuPercent: Double = 0,
        cpuTemp: Double? = nil,
        ramUsedPercent: Double = 0,
        networkReachable: Bool = true,
        downloadRate: Double = 0
    ) {
        self.cpuPercent = cpuPercent
        self.cpuTemp = cpuTemp
        self.ramUsedPercent = ramUsedPercent
        self.networkReachable = networkReachable
        self.downloadRate = downloadRate
    }
}

public final class SystemMonitor: ObservableObject {
    #if canImport(Combine)
    @Published public private(set) var stats: SystemStats
    #else
    public private(set) var stats: SystemStats
    #endif
    public var onUpdate: ((SystemStats) -> Void)?
    public var pollInterval: TimeInterval

    private let cpuProvider: CPUProviding
    private let memoryProvider: MemoryProviding
    private let networkProvider: NetworkProviding
    private let downloadProvider: DownloadProviding
    private let queue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var cpuFilter = EmaFilter(alpha: 0.25)

    public init(
        cpuProvider: CPUProviding = defaultCPUProvider(),
        memoryProvider: MemoryProviding = MemoryStub(),
        networkProvider: NetworkProviding = NetworkStub(),
        downloadProvider: DownloadProviding = DownloadStub(),
        pollInterval: TimeInterval = 1.0,
        queue: DispatchQueue = DispatchQueue(label: "com.mochi.systemmonitor")
    ) {
        self.cpuProvider = cpuProvider
        self.memoryProvider = memoryProvider
        self.networkProvider = networkProvider
        self.downloadProvider = downloadProvider
        self.pollInterval = pollInterval
        self.queue = queue
        self.stats = SystemStats()
    }

    public func start() {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: pollInterval, leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            self?.pollOnce()
        }
        timer.resume()
        self.timer = timer
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Executes a single poll cycle using providers.
    internal func pollOnce() {
        let rawCpu = cpuProvider.cpuPercent() ?? stats.cpuPercent
        let cpu = cpuFilter.update(sample: clampPercent(rawCpu))
        let ram = memoryProvider.ramUsedPercent() ?? stats.ramUsedPercent
        let reachable = networkProvider.isReachable()
        let download = downloadProvider.downloadRate() ?? stats.downloadRate
        let next = SystemStats(
            cpuPercent: clampPercent(cpu),
            cpuTemp: stats.cpuTemp,
            ramUsedPercent: clampPercent(ram),
            networkReachable: reachable,
            downloadRate: max(download, 0)
        )
        publish(next)
    }

    private func publish(_ next: SystemStats) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.stats = next
            self.onUpdate?(next)
        }
    }

    private func clampPercent(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }
}

// MARK: - Default stub providers (lightweight placeholders)

public func defaultCPUProvider() -> CPUProviding {
#if os(macOS)
    return CPUMachProvider()
#else
    return CPUStub()
#endif
}

public struct CPUStub: CPUProviding {
    public init() {}
    public func cpuPercent() -> Double? { Double.random(in: 8...35) }
}

public struct MemoryStub: MemoryProviding {
    public init() {}
    public func ramUsedPercent() -> Double? { Double.random(in: 30...65) }
}

public struct NetworkStub: NetworkProviding {
    public init() {}
    public func isReachable() -> Bool { true }
}

public struct DownloadStub: DownloadProviding {
    public init() {}
    public func downloadRate() -> Double? { Double.random(in: 0...50_000) }
}
