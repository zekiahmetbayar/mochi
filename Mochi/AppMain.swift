#if os(macOS)
import SwiftUI
import MochiCore

@main
struct MochiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#else
import Foundation
import MochiCore

@main
struct MochiLauncher {
    static func main() {
        // Non-macOS placeholder keeps CI builds lightweight.
        print("Mochi bootstrap placeholder")
    }
}
#endif
