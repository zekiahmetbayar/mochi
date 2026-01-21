import Foundation

public enum MochiMood {
    case normal
    case chonky
    case sweating
    case sleeping
    case carrying
}

public struct SpriteFrame: Equatable {
    public let imageName: String
    public let duration: TimeInterval

    public init(imageName: String, duration: TimeInterval) {
        self.imageName = imageName
        self.duration = duration
    }
}

public struct SpriteAnimation: Equatable {
    public let frames: [SpriteFrame]
    public let loop: Bool

    public init(frames: [SpriteFrame], loop: Bool) {
        self.frames = frames
        self.loop = loop
    }

    public var totalDuration: TimeInterval {
        frames.reduce(0) { $0 + max($1.duration, 0) }
    }

    public func frame(at index: Int) -> SpriteFrame? {
        guard frames.indices.contains(index) else { return nil }
        return frames[index]
    }

    /// Returns the frame index for a given elapsed time.
    /// Loops when `loop == true`, otherwise clamps to last frame.
    public func frameIndex(at elapsed: TimeInterval) -> Int {
        guard !frames.isEmpty else { return 0 }
        let safeElapsed = max(elapsed, 0)
        let duration = totalDuration
        if duration == 0 { return 0 }

        var remaining = loop ? safeElapsed.truncatingRemainder(dividingBy: duration) : safeElapsed

        for (idx, frame) in frames.enumerated() {
            let span = max(frame.duration, 0)
            if remaining < span {
                return idx
            } else {
                remaining -= span
            }
        }
        return frames.count - 1
    }
}
