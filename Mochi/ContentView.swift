#if os(macOS)
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Mochi")
                .font(.title)
                .bold()
            Text("Menu-bar overlay coming soon")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(minWidth: 280, minHeight: 180)
    }
}
#endif
