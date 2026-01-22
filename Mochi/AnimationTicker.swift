#if os(macOS)
import Foundation
import Combine

/// Drives animation ticks with a DispatchSourceTimer and leeway to reduce CPU.
final class AnimationTicker: ObservableObject {
    @Published var tick: Date = Date()

    private var timer: DispatchSourceTimer?
    private var interval: TimeInterval
    private let queue: DispatchQueue
    private let leeway: DispatchTimeInterval

    init(fps: Double = 24.0, leewayMilliseconds: Int = 12, queue: DispatchQueue = .main) {
        self.interval = max(1.0 / fps, 0.01)
        self.queue = queue
        self.leeway = .milliseconds(max(leewayMilliseconds, 0))
    }

    func start() {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: leeway)
        timer.setEventHandler { [weak self] in
            self?.tick = Date()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func setFPS(_ fps: Double) {
        interval = max(1.0 / fps, 0.01)
        if timer != nil {
            start()
        }
    }
}
#endif
