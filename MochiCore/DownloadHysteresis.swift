import Foundation

/// Tracks download "heavy" state with hysteresis.
/// Enter when rate >= enterRate for enterSeconds; exit when rate <= exitRate for exitSeconds.
public struct DownloadHysteresis {
    public var enterRate: Double
    public var exitRate: Double
    public var enterSeconds: Double
    public var exitSeconds: Double

    private var enterAccum: Double = 0
    private var exitAccum: Double = 0
    private var isHeavy: Bool = false

    public init(
        enterRate: Double = 150_000, // ~150 KB/s
        exitRate: Double = 75_000,   // ~75 KB/s
        enterSeconds: Double = 2.0,
        exitSeconds: Double = 2.0
    ) {
        self.enterRate = enterRate
        self.exitRate = exitRate
        self.enterSeconds = max(enterSeconds, 0)
        self.exitSeconds = max(exitSeconds, 0)
    }

    public mutating func update(rate: Double, dt: Double) -> Bool {
        let clampedDt = max(dt, 0)
        if rate >= enterRate {
            enterAccum += clampedDt
        } else {
            enterAccum = 0
        }

        if rate <= exitRate {
            exitAccum += clampedDt
        } else {
            exitAccum = 0
        }

        if !isHeavy, enterAccum >= enterSeconds {
            isHeavy = true
            exitAccum = 0
        } else if isHeavy, exitAccum >= exitSeconds {
            isHeavy = false
            enterAccum = 0
        }
        return isHeavy
    }
}
