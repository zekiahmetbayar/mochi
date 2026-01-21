#if os(macOS)
import SwiftUI
import MochiCore

struct ContentView: View {
    private let demoAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_idle_0", duration: 0.1),
            SpriteFrame(imageName: "mochi_idle_1", duration: 0.1)
        ],
        loop: true
    )

    var body: some View {
        VStack(spacing: 16) {
            SpriteRendererView(animation: demoAnimation) { frame in
                ZStack {
                    Color(red: 1.0, green: 0.95, blue: 0.4, opacity: 0.8)
                    Image(frame.imageName, bundle: .module)
                        .renderingMode(.original)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 64, height: 48)
                        .border(Color.black.opacity(0.3), width: 1)
                    Text(frame.imageName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.8))
                        .padding(.top, 44)
                }
                .frame(width: 96, height: 72)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.blue.opacity(0.4), lineWidth: 1))
                .shadow(radius: 1, y: 1)
            }
            VStack(spacing: 8) {
                Text("Mochi")
                    .font(.title2)
                    .bold()
                Text("Menu-bar overlay coming soon")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(minWidth: 300, minHeight: 260)
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }
}
#endif
