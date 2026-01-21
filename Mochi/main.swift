import Foundation

/// Lightweight status helper used by smoke tests.
public enum Bootstrap {
    public static let targetVersion = "0.0.1"
    public static func status() -> String { "ready" }
}

#if os(macOS)
import SwiftUI

@main
struct MochiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#else
@main
struct MochiLauncher {
    static func main() {
        // Keep runtime side-effects minimal for non-macOS builds (e.g., CI in Linux containers).
        print("Mochi bootstrap placeholder")
    }
}
#endif
