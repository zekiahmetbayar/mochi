import Foundation
#if os(macOS)
import Network
#endif

public protocol NetworkReachabilityProviding: NetworkProviding {}

#if os(macOS)
public final class NetworkPathProvider: NetworkReachabilityProviding {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mochi.network.monitor")
    private var reachable: Bool = true

    public init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.queue.async {
                self?.reachable = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    public func isReachable() -> Bool {
        var value = true
        queue.sync {
            value = reachable
        }
        return value
    }
}
#else
public final class NetworkPathProvider: NetworkReachabilityProviding {
    public init() {}
    public func isReachable() -> Bool { true }
}
#endif
