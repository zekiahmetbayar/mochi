import Foundation

/// Represents Mochi's current presentation state.
public struct MochiState: Equatable {
    public var mood: MochiMood
    public var speedMultiplier: Double

    public init(mood: MochiMood = .normal, speedMultiplier: Double = 1.0) {
        self.mood = mood
        self.speedMultiplier = speedMultiplier
    }
}

/// Simple hysteresis-based state machine mapping `SystemStats` to `MochiState`.
public final class MochiStateMachine {
    // Thresholds / durations (seconds)
    public var sleepEnterSeconds: Double = 2.0
    public var sleepExitSeconds: Double = 1.0

    public var bagThreshold: Double = 100_000 // bytes/sec (~100 KB/s)
    public var bagEnterSeconds: Double = 3.0
    public var bagExitSeconds: Double = 2.0

    public var sweatThreshold: Double = 70.0 // percent
    public var sweatEnterSeconds: Double = 8.0
    public var sweatExitSeconds: Double = 4.0

    public var chonkThreshold: Double = 75.0 // percent
    public var chonkEnterSeconds: Double = 10.0
    public var chonkExitSeconds: Double = 5.0

    private var sleepOn = false
    private var bagOn = false
    private var sweatOn = false
    private var chonkOn = false

    private var sleepEnterAccum: Double = 0
    private var sleepExitAccum: Double = 0
    private var bagEnterAccum: Double = 0
    private var bagExitAccum: Double = 0
    private var sweatEnterAccum: Double = 0
    private var sweatExitAccum: Double = 0
    private var chonkEnterAccum: Double = 0
    private var chonkExitAccum: Double = 0

    public init() {}

    /// Updates internal state and returns the derived `MochiState`.
    /// - Parameters:
    ///   - stats: latest system stats sample
    ///   - dt: elapsed seconds since last update
    public func update(stats: SystemStats, dt: TimeInterval) -> MochiState {
        let delta = max(dt, 0)

        sleepOn = evaluate(
            condition: !stats.networkReachable,
            current: sleepOn,
            enterAccum: &sleepEnterAccum,
            exitAccum: &sleepExitAccum,
            enterSeconds: sleepEnterSeconds,
            exitSeconds: sleepExitSeconds,
            dt: delta
        )

        let bagCondition = stats.downloadRate >= bagThreshold || stats.downloadHeavy
        bagOn = evaluate(
            condition: bagCondition,
            current: bagOn,
            enterAccum: &bagEnterAccum,
            exitAccum: &bagExitAccum,
            enterSeconds: bagEnterSeconds,
            exitSeconds: bagExitSeconds,
            dt: delta
        )

        sweatOn = evaluate(
            condition: stats.cpuPercent >= sweatThreshold || stats.cpuHot,
            current: sweatOn,
            enterAccum: &sweatEnterAccum,
            exitAccum: &sweatExitAccum,
            enterSeconds: sweatEnterSeconds,
            exitSeconds: sweatExitSeconds,
            dt: delta
        )

        chonkOn = evaluate(
            condition: stats.ramUsedPercent >= chonkThreshold,
            current: chonkOn,
            enterAccum: &chonkEnterAccum,
            exitAccum: &chonkExitAccum,
            enterSeconds: chonkEnterSeconds,
            exitSeconds: chonkExitSeconds,
            dt: delta
        )

        // Priority: sleep > bag > sweat > chonk > normal
        let mood: MochiMood
        if sleepOn {
            mood = .sleeping
        } else if bagOn {
            mood = .carrying
        } else if sweatOn {
            mood = .sweating
        } else if chonkOn {
            mood = .chonky
        } else {
            mood = .normal
        }

        let speedMultiplier: Double = chonkOn ? 0.7 : 1.0
        return MochiState(mood: mood, speedMultiplier: speedMultiplier)
    }

    private func evaluate(
        condition: Bool,
        current: Bool,
        enterAccum: inout Double,
        exitAccum: inout Double,
        enterSeconds: Double,
        exitSeconds: Double,
        dt: Double
    ) -> Bool {
        let enterDur = max(enterSeconds, 0)
        let exitDur = max(exitSeconds, 0)

        if condition {
            enterAccum += dt
            exitAccum = 0
        } else {
            exitAccum += dt
            enterAccum = 0
        }

        var next = current
        if !current, enterAccum >= enterDur {
            next = true
            exitAccum = 0
        } else if current, exitAccum >= exitDur {
            next = false
            enterAccum = 0
        }
        return next
    }
}
