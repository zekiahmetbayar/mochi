import Foundation

/// Tracks sustained high CPU load with hysteresis to avoid flicker.
public struct CPULoadHysteresis {
    public var enterPercent: Double
    public var exitPercent: Double
    public var enterSeconds: Double
    public var exitSeconds: Double

    private var enterAccum: Double = 0
    private var exitAccum: Double = 0
    private var isHot: Bool = false

    public init(
        enterPercent: Double = 70,
        exitPercent: Double = 60,
        enterSeconds: Double = 8.0,
        exitSeconds: Double = 6.0
    ) {
        self.enterPercent = enterPercent
        self.exitPercent = exitPercent
        self.enterSeconds = max(enterSeconds, 0)
        self.exitSeconds = max(exitSeconds, 0)
    }

    public mutating func update(percent: Double, dt: Double) -> Bool {
        let clampedDt = max(dt, 0)
        if percent >= enterPercent {
            enterAccum += clampedDt
        } else {
            enterAccum = 0
        }

        if percent <= exitPercent {
            exitAccum += clampedDt
        } else {
            exitAccum = 0
        }

        if !isHot, enterAccum >= enterSeconds {
            isHot = true
            exitAccum = 0
        } else if isHot, exitAccum >= exitSeconds {
            isHot = false
            enterAccum = 0
        }
        return isHot
    }
}
