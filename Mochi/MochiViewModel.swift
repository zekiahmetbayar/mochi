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
    @Published var showOnboarding: Bool = false

    private let monitor: SystemMonitor
    private let stateMachine: MochiStateMachine
    private var lastUpdate: Date
    private let now: () -> Date
    private let onboardingStore: OnboardingPersisting

    init(
        monitor: SystemMonitor = SystemMonitor(),
        stateMachine: MochiStateMachine = MochiStateMachine(),
        onboardingStore: OnboardingPersisting = UserDefaultsOnboardingStore(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.monitor = monitor
        self.stateMachine = stateMachine
        self.onboardingStore = onboardingStore
        self.now = now
        self.animation = MochiViewModel.idleAnimation
        self.stats = monitor.stats
        self.lastUpdate = now()
        self.showOnboarding = !onboardingStore.hasSeenOnboarding()
        wire()
    }

    func start() {
        lastUpdate = now()
        monitor.start()
    }

    func stop() {
        monitor.stop()
    }

    func dismissOnboarding() {
        onboardingStore.setSeen()
        showOnboarding = false
    }

    func applySettings(_ settings: SettingsState) {
        stateMachine.bagThreshold = settings.downloadThreshold
        stateMachine.sweatThreshold = settings.cpuThreshold
        stateMachine.chonkThreshold = settings.ramThreshold
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

    // Backward-compat: default-pet aliases for existing call sites/tests.
    static var idleAnimation: SpriteAnimation { idleAnimation(for: .cat) }
    static var walkAnimation: SpriteAnimation { walkAnimation(for: .cat) }
    static var sitAnimation: SpriteAnimation { sitAnimation(for: .cat) }
    static var lookAnimation: SpriteAnimation { lookAnimation(for: .cat) }
    static var rollAnimation: SpriteAnimation { rollAnimation(for: .cat) }
    static var sleepAnimation: SpriteAnimation { sleepAnimation(for: .cat) }
    static var sweatAnimation: SpriteAnimation { sweatAnimation(for: .cat) }
    static var chonkAnimation: SpriteAnimation { chonkAnimation(for: .cat) }
    static var bagAnimation: SpriteAnimation { bagAnimation(for: .cat) }

    static func idleAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [
                SpriteFrame(imageName: "\(pet.spritePrefix)_idle_0", duration: 0.12),
                SpriteFrame(imageName: "\(pet.spritePrefix)_idle_1", duration: 0.12)
            ],
            loop: true
        )
    }

    static func walkAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: (0...3).map {
                SpriteFrame(imageName: "\(pet.spritePrefix)_walk_\($0)", duration: 0.12)
            },
            loop: true
        )
    }

    static func sitAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [SpriteFrame(imageName: "\(pet.spritePrefix)_sit_0", duration: 0.4)],
            loop: true
        )
    }

    static func lookAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [
                SpriteFrame(imageName: "\(pet.spritePrefix)_look_0", duration: 0.35),
                SpriteFrame(imageName: "\(pet.spritePrefix)_look_1", duration: 0.2)
            ],
            loop: true
        )
    }

    static func rollAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [
                SpriteFrame(imageName: "\(pet.spritePrefix)_roll_0", duration: 0.14),
                SpriteFrame(imageName: "\(pet.spritePrefix)_roll_1", duration: 0.14),
                SpriteFrame(imageName: "\(pet.spritePrefix)_roll_2", duration: 0.14),
                SpriteFrame(imageName: "\(pet.spritePrefix)_roll_1", duration: 0.14)
            ],
            loop: true
        )
    }

    static func sleepAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [SpriteFrame(imageName: "\(pet.spritePrefix)_sleep_0", duration: 0.25)],
            loop: true
        )
    }

    static func sweatAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [SpriteFrame(imageName: "\(pet.spritePrefix)_sweat_0", duration: 0.2)],
            loop: true
        )
    }

    static func chonkAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [SpriteFrame(imageName: "\(pet.spritePrefix)_chonk_0", duration: 0.2)],
            loop: true
        )
    }

    static func bagAnimation(for pet: PetKind) -> SpriteAnimation {
        SpriteAnimation(
            frames: [SpriteFrame(imageName: "\(pet.spritePrefix)_bag_0", duration: 0.2)],
            loop: true
        )
    }

    static let portalInAnimation = SpriteAnimation(
        frames: [SpriteFrame(imageName: "mochi_portal_in", duration: 0.15)],
        loop: true
    )

    static let portalOutAnimation = SpriteAnimation(
        frames: [SpriteFrame(imageName: "mochi_portal_out", duration: 0.15)],
        loop: true
    )
}
#endif
