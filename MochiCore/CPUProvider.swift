import Foundation
#if os(macOS)
import Darwin
#else
// Minimal CPU state constants for non-macOS so helper math and tests compile.
let CPU_STATE_USER: Int32 = 0
let CPU_STATE_NICE: Int32 = 1
let CPU_STATE_SYSTEM: Int32 = 2
let CPU_STATE_IDLE: Int32 = 3
let CPU_STATE_MAX: Int32 = 4
#endif

/// Calculates CPU usage percent using host CPU load ticks.
/// Returns a total normalized 0...100 across all cores.
public protocol CPULoadProviding: CPUProviding {}

#if os(macOS)
public final class CPUMachProvider: CPULoadProviding {
    private var previous: [UInt32]?

    public init() {}

    public func cpuPercent() -> Double? {
        guard let current = readTicks() else { return nil }
        guard let prev = previous else {
            previous = current
            return nil
        }
        previous = current
        return CPUNormalizer.percent(previous: prev, current: current)
    }

    private func readTicks() -> [UInt32]? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return CPUNormalizer.ticksArray(info)
    }
}
#else
/// Non-macOS fallback returns a mild random value.
public final class CPUMachProvider: CPULoadProviding {
    public init() {}
    public func cpuPercent() -> Double? { Double.random(in: 5...25) }
}
#endif

// MARK: - Helpers

public enum CPUNormalizer {
    #if os(macOS)
    public static func ticksArray(_ info: host_cpu_load_info) -> [UInt32] {
        var copy = info
        return withUnsafePointer(to: &copy.cpu_ticks) {
            $0.withMemoryRebound(to: UInt32.self, capacity: Int(CPU_STATE_MAX)) {
                Array(UnsafeBufferPointer(start: $0, count: Int(CPU_STATE_MAX)))
            }
        }
    }
    #endif

    /// Computes total CPU percent (user+sys+nice) / total * 100
    public static func percent(previous: [UInt32], current: [UInt32]) -> Double? {
        guard previous.count == Int(CPU_STATE_MAX), current.count == Int(CPU_STATE_MAX) else { return nil }
        let deltas = zip(current, previous).map { curr, prev in curr &- prev }
        let user = deltas[Int(CPU_STATE_USER)]
        let nice = deltas[Int(CPU_STATE_NICE)]
        let sys = deltas[Int(CPU_STATE_SYSTEM)]
        let idle = deltas[Int(CPU_STATE_IDLE)]
        let total = user &+ nice &+ sys &+ idle
        guard total > 0 else { return nil }
        let active = user &+ nice &+ sys
        return Double(active) / Double(total) * 100.0
    }
}

/// Lightweight EMA filter to smooth noisy samples.
public struct EmaFilter {
    private let alpha: Double
    private var state: Double?

    public init(alpha: Double = 0.2) {
        self.alpha = max(0, min(alpha, 1))
    }

    public mutating func update(sample: Double) -> Double {
        if let prev = state {
            let next = alpha * sample + (1 - alpha) * prev
            state = next
            return next
        } else {
            state = sample
            return sample
        }
    }
}
