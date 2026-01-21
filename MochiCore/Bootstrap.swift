import Foundation

/// Lightweight status helper used by smoke tests and future wiring.
public enum Bootstrap {
    public static let targetVersion = "0.0.1"
    public static func status() -> String { "ready" }
}
