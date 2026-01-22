import Foundation
#if os(macOS)
import Darwin
#endif

public protocol DownloadProviding {
    /// Returns current download rate in bytes per second.
    func downloadRate() -> Double?
}

#if os(macOS)
public final class GetIfAddrsDownloadProvider: DownloadProviding {
    private var lastBytes: UInt64?
    private var lastTime: Date?

    public init() {}

    public func downloadRate() -> Double? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var totalIn: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor?.pointee {
            // Skip loopback
            if (ifa.ifa_flags & UInt32(IFF_LOOPBACK)) != 0 {
                cursor = ifa.ifa_next
                continue
            }
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = unsafeBitCast(ifa.ifa_data, to: UnsafeMutablePointer<if_data>?.self)?.pointee {
                    totalIn += UInt64(data.ifi_ibytes)
                }
            }
            cursor = ifa.ifa_next
        }
        let now = Date()
        defer {
            lastBytes = totalIn
            lastTime = now
        }
        guard let prevBytes = lastBytes, let prevTime = lastTime else {
            return 0
        }
        let deltaBytes = totalIn &- prevBytes
        let dt = now.timeIntervalSince(prevTime)
        guard dt > 0 else { return nil }
        return Double(deltaBytes) / dt
    }
}
#else
public final class GetIfAddrsDownloadProvider: DownloadProviding {
    public init() {}
    public func downloadRate() -> Double? { nil }
}
#endif
