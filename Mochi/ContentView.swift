#if os(macOS)
import SwiftUI
import MochiCore

struct ContentView: View {
    private let demoAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "idle_a", duration: 0.08),
            SpriteFrame(imageName: "idle_b", duration: 0.08),
            SpriteFrame(imageName: "idle_a", duration: 0.08),
            SpriteFrame(imageName: "idle_c", duration: 0.08)
        ],
        loop: true
    )

    var body: some View {
        VStack(spacing: 16) {
            SpriteRendererView(animation: demoAnimation) { frame in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 96, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.35), lineWidth: 1)
                        )
                    Text(frame.imageName)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(6)
                }
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
