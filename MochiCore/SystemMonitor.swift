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

public struct SystemStats: Equatable {
    public var cpuPercent: Double
    public var cpuTemp: Double?
    public var cpuHot: Bool
    public var ramUsedPercent: Double
    public var networkReachable: Bool
    public var downloadRate: Double
    public var downloadHeavy: Bool

    public init(
        cpuPercent: Double = 0,
        cpuTemp: Double? = nil,
        cpuHot: Bool = false,
        ramUsedPercent: Double = 0,
        networkReachable: Bool = true,
        downloadRate: Double = 0,
        downloadHeavy: Bool = false
    ) {
        self.cpuPercent = cpuPercent
        self.cpuTemp = cpuTemp
        self.cpuHot = cpuHot
        self.ramUsedPercent = ramUsedPercent
        self.networkReachable = networkReachable
        self.downloadRate = downloadRate
        self.downloadHeavy = downloadHeavy
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
    private var lastPublished: SystemStats?
    private var cpuFilter = EmaFilter(alpha: 0.25)
    private var cpuHotHysteresis = CPULoadHysteresis()
    private var downloadHysteresis = DownloadHysteresis()

    public init(
        cpuProvider: CPUProviding = defaultCPUProvider(),
        memoryProvider: MemoryProviding = defaultMemoryProvider(),
        networkProvider: NetworkProviding = defaultNetworkProvider(),
        downloadProvider: DownloadProviding = defaultDownloadProvider(),
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
        let cpuHot = cpuHotHysteresis.update(
            percent: clampPercent(cpu),
            dt: pollInterval
        )
        let heavy = downloadHysteresis.update(
            rate: max(download, 0),
            dt: pollInterval
        )
        let next = SystemStats(
            cpuPercent: clampPercent(cpu),
            cpuTemp: stats.cpuTemp,
            cpuHot: cpuHot,
            ramUsedPercent: clampPercent(ram),
            networkReachable: reachable,
            downloadRate: max(download, 0),
            downloadHeavy: heavy
        )
        publishIfNeeded(next)
    }

    private func publishIfNeeded(_ next: SystemStats) {
        if let last = lastPublished, !isSignificantChange(from: last, to: next) {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.stats = next
            self.onUpdate?(next)
            self.lastPublished = next
        }
    }

    private func clampPercent(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    private func isSignificantChange(from old: SystemStats, to new: SystemStats) -> Bool {
        let cpuDelta = abs(old.cpuPercent - new.cpuPercent)
        let ramDelta = abs(old.ramUsedPercent - new.ramUsedPercent)
        let dlDelta = abs(old.downloadRate - new.downloadRate)
        return cpuDelta > 0.5
            || ramDelta > 0.5
            || dlDelta > 5_000 // ~5 KB/s
            || old.cpuHot != new.cpuHot
            || old.networkReachable != new.networkReachable
            || old.downloadHeavy != new.downloadHeavy
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

public func defaultMemoryProvider() -> MemoryProviding {
#if os(macOS)
    return MemoryMachProvider()
#else
    return MemoryStub()
#endif
}

public func defaultNetworkProvider() -> NetworkProviding {
#if os(macOS)
    return NetworkPathProvider()
#else
    return NetworkStub()
#endif
}

public func defaultDownloadProvider() -> DownloadProviding {
#if os(macOS)
    return GetIfAddrsDownloadProvider()
#else
    return DownloadStub()
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
