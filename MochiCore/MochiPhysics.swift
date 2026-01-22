import Foundation

/// Deterministic RNG (LCG) to enable reproducible physics in tests.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { self.state = seed }
    public mutating func next() -> UInt64 {
        // Constants from Numerical Recipes
        state = 1664525 &* state &+ 1013904223
        return state
    }
}

public struct MochiPhysics {
    public var positionX: Double
    public var velocityX: Double
    public var boundsWidth: Double
    public var speed: Double
    public var speedMultiplier: Double
    public var timeUntilTurn: Double
    public var minTurnInterval: Double
    public var maxTurnInterval: Double
    private var rng: SeededGenerator

    public init(boundsWidth: Double, seed: UInt64 = 42, speed: Double = 60, minTurnInterval: Double = 2.0, maxTurnInterval: Double = 4.0) {
        self.boundsWidth = max(boundsWidth, 1)
        self.positionX = self.boundsWidth / 2
        self.speed = speed
        self.speedMultiplier = 1.0
        self.velocityX = speed
        self.minTurnInterval = max(0.1, min(minTurnInterval, maxTurnInterval))
        self.maxTurnInterval = max(self.minTurnInterval, maxTurnInterval)
        self.timeUntilTurn = self.minTurnInterval
        self.rng = SeededGenerator(seed: seed)
    }

    /// Advances physics by dt seconds with simple random walk + edge bounce.
    public mutating func step(dt: Double) {
        let dtClamped = max(dt, 0)
        timeUntilTurn -= dtClamped
        if timeUntilTurn <= 0 {
            chooseNewVelocity()
            timeUntilTurn = minTurnInterval + random01() * (maxTurnInterval - minTurnInterval)
        }

        positionX += velocityX * dtClamped

        // Bounce on edges
        if positionX < 0 {
            positionX = 0
            velocityX = abs(velocityX)
        } else if positionX > boundsWidth {
            positionX = boundsWidth
            velocityX = -abs(velocityX)
        }
    }

    /// Updates bounds and clamps position.
    public mutating func updateBounds(width: Double) {
        boundsWidth = max(width, 1)
        positionX = min(max(positionX, 0), boundsWidth)
    }

    /// Adjusts movement speed multiplier (e.g., slower when chonky).
    public mutating func setSpeedMultiplier(_ multiplier: Double) {
        let clamped = max(multiplier, 0)
        let direction = velocityX >= 0 ? 1.0 : -1.0
        speedMultiplier = clamped
        velocityX = direction * speed * speedMultiplier
    }

    private mutating func chooseNewVelocity() {
        let direction = random01() > 0.5 ? 1.0 : -1.0
        velocityX = direction * speed * speedMultiplier
    }

    private mutating func random01() -> Double {
        Double(rng.next() % 10_000) / 10_000.0
    }
}
