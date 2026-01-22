import Foundation
#if os(macOS)
import SwiftUI
import MochiCore

@MainActor
final class MochiViewModel: ObservableObject {
    @Published var animation: SpriteAnimation
    @Published var stats: SystemStats
    @Published var mood: MochiMood = .normal
    @Published var speedMultiplier: Double = 1.0

    private let monitor: SystemMonitor
    private let stateMachine: MochiStateMachine
    private var lastUpdate: Date
    private let now: () -> Date

    init(
        monitor: SystemMonitor = SystemMonitor(),
        stateMachine: MochiStateMachine = MochiStateMachine(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.monitor = monitor
        self.stateMachine = stateMachine
        self.now = now
        self.animation = MochiViewModel.idleAnimation
        self.stats = monitor.stats
        self.lastUpdate = now()
        wire()
    }

    func start() {
        lastUpdate = now()
        monitor.start()
    }

    func stop() {
        monitor.stop()
    }

    private func wire() {
        monitor.onUpdate = { [weak self] stats in
            guard let self else { return }
            let currentTime = self.now()
            let dt = currentTime.timeIntervalSince(self.lastUpdate)
            self.lastUpdate = currentTime

            let mochiState = self.stateMachine.update(stats: stats, dt: dt)
            self.mood = mochiState.mood
            self.animation = self.animation(for: mochiState.mood)
            self.speedMultiplier = mochiState.speedMultiplier
            self.stats = stats
        }
    }

    // MARK: Animations

    private func animation(for mood: MochiMood) -> SpriteAnimation {
        switch mood {
        case .sleeping:
            return Self.sleepAnimation
        case .carrying:
            return Self.bagAnimation
        case .sweating:
            return Self.sweatAnimation
        case .chonky:
            return Self.chonkAnimation
        case .normal:
            return Self.idleAnimation
        }
    }

    static let idleAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_idle_0", duration: 0.12),
            SpriteFrame(imageName: "mochi_idle_1", duration: 0.12)
        ],
        loop: true
    )

    static let walkAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_walk_0", duration: 0.12),
            SpriteFrame(imageName: "mochi_walk_1", duration: 0.12),
            SpriteFrame(imageName: "mochi_walk_2", duration: 0.12),
            SpriteFrame(imageName: "mochi_walk_3", duration: 0.12)
        ],
        loop: true
    )

    static let sitAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_sit_0", duration: 0.4)
        ],
        loop: true
    )

    static let lookAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_look_0", duration: 0.35),
            SpriteFrame(imageName: "mochi_look_1", duration: 0.2)
        ],
        loop: true
    )

    static let rollAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_roll_0", duration: 0.14),
            SpriteFrame(imageName: "mochi_roll_1", duration: 0.14),
            SpriteFrame(imageName: "mochi_roll_2", duration: 0.14),
            SpriteFrame(imageName: "mochi_roll_1", duration: 0.14)
        ],
        loop: true
    )

    static let sleepAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_sleep_0", duration: 0.25)
        ],
        loop: true
    )

    static let sweatAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_sweat_0", duration: 0.2)
        ],
        loop: true
    )

    static let chonkAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_chonk_0", duration: 0.2)
        ],
        loop: true
    )

    static let bagAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_bag_0", duration: 0.2)
        ],
        loop: true
    )
}
#endif
