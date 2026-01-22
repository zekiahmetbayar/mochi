import Foundation

public protocol StartAtLoginControlling {
    var isSupported: Bool { get }
    var isEnabled: Bool { get }
    @discardableResult
    func setEnabled(_ enable: Bool) -> Bool
}

/// Pure helper that applies desired login state via a controller, avoiding redundant calls.
public struct StartAtLoginCoordinator {
    private let controller: StartAtLoginControlling

    public init(controller: StartAtLoginControlling) {
        self.controller = controller
    }

    public var isEnabled: Bool { controller.isEnabled }
    public var isSupported: Bool { controller.isSupported }

    /// Applies the desired state. Returns true on success or if already matching.
    @discardableResult
    public func apply(desired: Bool) -> Bool {
        guard controller.isSupported else { return false }
        if controller.isEnabled == desired { return true }
        return controller.setEnabled(desired)
    }
}
