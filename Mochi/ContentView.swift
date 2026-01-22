#if os(macOS)
import SwiftUI
import MochiCore

struct ContentView: View {
    @EnvironmentObject private var overlayBridge: OverlayBridge
    @State private var physics = MochiPhysics(boundsWidth: 400, seed: 99, speed: 60)
    @State private var lastTick: Date = .now
    @State private var showSettings = false
    @StateObject private var systemMonitor = SystemMonitor()
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let spriteSize = CGSize(width: 96, height: 72)
    private let menuBarHeight = NSStatusBar.system.thickness

    private let idleAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_idle_0", duration: 0.1),
            SpriteFrame(imageName: "mochi_idle_1", duration: 0.1)
        ],
        loop: true
    )
    private let bagAnimation = SpriteAnimation(
        frames: [
            SpriteFrame(imageName: "mochi_bag_0", duration: 0.2)
        ],
        loop: true
    )

    private var currentAnimation: SpriteAnimation {
        systemMonitor.stats.downloadHeavy ? bagAnimation : idleAnimation
    }

    var body: some View {
        GeometryReader { geo in
            MochiOverlayView(
                animation: currentAnimation,
                spriteSize: spriteSize,
                menuBarHeight: menuBarHeight,
                positionX: physics.positionX,
                hangOffset: 0,
                showSettings: $showSettings,
                spriteContent: spriteSpriteView,
                settingsContent: settingsContent
            )
            .allowsHitTesting(!overlayBridge.clickThrough)
            .background(Color.clear)
            .onAppear {
                let travelWidth = max(geo.size.width - spriteSize.width, 1)
                physics.updateBounds(width: travelWidth)
                lastTick = .now
                systemMonitor.start()
            }
            .onReceive(timer) { date in
                let dt = date.timeIntervalSince(lastTick)
                lastTick = date
                let travelWidth = max(geo.size.width - spriteSize.width, 1)
                physics.updateBounds(width: travelWidth)
                physics.step(dt: dt)
            }
            .onDisappear {
                systemMonitor.stop()
            }
        }
        .background(Color.clear)
        .ignoresSafeArea()
    }

    private func spriteSpriteView(frame: SpriteFrame) -> some View {
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
        .frame(width: spriteSize.width, height: spriteSize.height)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.blue.opacity(0.4), lineWidth: 1))
        .shadow(radius: 1, y: 1)
    }

    private func settingsContent() -> some View {
        SettingsPopoverView(
            clickThrough: $overlayBridge.clickThrough,
            stats: systemMonitor.stats,
            onQuit: { overlayBridge.quitApp() }
        )
        .padding()
    }
}

struct SettingsPopoverView: View {
    @Binding var clickThrough: Bool
    let stats: SystemStats
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.headline)
            Toggle("Click-through overlay", isOn: $clickThrough)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug (live)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("CPU: \(Int(stats.cpuPercent))%")
                Text("CPU Hot: \(stats.cpuHot ? "On" : "Off")")
                Text("RAM: \(Int(stats.ramUsedPercent))%")
                Text("Net: \(stats.networkReachable ? "Reachable" : "Offline")")
                Text("DL: \(formatBytes(stats.downloadRate))/s")
                Text("Bag mode: \(stats.downloadHeavy ? "On" : "Off")")
            }
            Divider()
            Button("Quit Mochi", action: onQuit)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(width: 220)
    }

    private func formatBytes(_ bytes: Double) -> String {
        let kb = bytes / 1024
        let mb = kb / 1024
        if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.0f KB", kb)
        } else {
            return String(format: "%.0f B", bytes)
        }
    }
}
#endif
