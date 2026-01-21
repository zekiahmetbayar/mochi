#if os(macOS)
import SwiftUI
import MochiCore

struct ContentView: View {
    @EnvironmentObject private var overlayBridge: OverlayBridge
    @State private var physics = MochiPhysics(boundsWidth: 400, seed: 99, speed: 60)
    @State private var lastTick: Date = .now
    @State private var showSettings = false
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private let demoAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_idle_0", duration: 0.1),
            SpriteFrame(imageName: "mochi_idle_1", duration: 0.1)
        ],
        loop: true
    )

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                spriteStrip
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: physics.positionX - 48)
                    .contentShape(Rectangle())
                    .onTapGesture { showSettings.toggle() }
                    .popover(isPresented: $showSettings, arrowEdge: .top) {
                        SettingsPopoverView(
                            clickThrough: $overlayBridge.clickThrough,
                            onQuit: { overlayBridge.quitApp() }
                        )
                        .padding()
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
            .frame(minWidth: 300, minHeight: 260, alignment: .topLeading)
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .onAppear {
                physics.updateBounds(width: geo.size.width)
                lastTick = .now
            }
            .onReceive(timer) { date in
                let dt = date.timeIntervalSince(lastTick)
                lastTick = date
                physics.updateBounds(width: geo.size.width)
                physics.step(dt: dt)
            }
        }
    }

    private var spriteStrip: some View {
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
    }
}

struct SettingsPopoverView: View {
    @Binding var clickThrough: Bool
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.headline)
            Toggle("Click-through overlay", isOn: $clickThrough)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug (placeholder)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("CPU: --%")
                Text("RAM: --%")
                Text("Net: --")
            }
            Divider()
            Button("Quit Mochi", action: onQuit)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(width: 220)
    }
}
#endif
