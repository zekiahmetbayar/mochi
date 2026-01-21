import Foundation

public protocol MemoryLoadProviding: MemoryProviding {}

#if os(macOS)
import Darwin

public final class MemoryMachProvider: MemoryLoadProviding {
    public init() {}

    public func ramUsedPercent() -> Double? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: stats) / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize
        let speculative = UInt64(stats.speculative_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize

        // macOS uses compressed memory; count it toward used.
        let used = active + inactive + wired + compressed + speculative - purgeable
        let total = used + free
        guard total > 0 else { return nil }
        return Double(used) / Double(total) * 100.0
    }
}
#else
public final class MemoryMachProvider: MemoryLoadProviding {
    public init() {}
    public func ramUsedPercent() -> Double? { Double.random(in: 40...75) }
}
#endif
