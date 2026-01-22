import Foundation

public protocol OverlayControlling: AnyObject {
    func show()
    func hide()
    func move(toX: Double)
}

public enum OverlayLifecycleState: Equatable {
    case idle
    case shown
}

/// Manages showing/hiding the overlay while remaining testable via protocol injection.
public final class OverlayLifecycle {
    private var controller: OverlayControlling?
    private(set) public var state: OverlayLifecycleState = .idle

    public init(controller: OverlayControlling? = nil) {
        self.controller = controller
    }

    public func setController(_ controller: OverlayControlling) {
        self.controller = controller
    }

    @discardableResult
    public func start() -> OverlayLifecycleState {
        guard state == .idle, let controller else { return state }
        controller.show()
        state = .shown
        return state
    }

    @discardableResult
    public func stop() -> OverlayLifecycleState {
        guard state == .shown else { return state }
        controller?.hide()
        state = .idle
        return state
    }
}
