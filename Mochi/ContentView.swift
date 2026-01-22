#if os(macOS)
import AppKit
import SwiftUI
import MochiCore

private enum CatBehavior: CaseIterable {
    case walk
    case sit
    case look
    case nap
}

struct ContentView: View {
    @EnvironmentObject private var overlayBridge: OverlayBridge
    @State private var physics = MochiPhysics(boundsWidth: 400, seed: 99, speed: 22, minTurnInterval: 3.5, maxTurnInterval: 5.5)
    @State private var lastTick: Date = .now
    @State private var showSettings = false
    @StateObject private var viewModel = MochiViewModel()
    @State private var behavior: CatBehavior = .walk
    @State private var behaviorDeadline: Date = .now
    @State private var isHovered: Bool = false
    private let timer = Timer.publish(every: 1.0 / 24.0, on: .main, in: .common).autoconnect()
    private let baseSpriteSize = CGSize(width: 64, height: 32)
    private let menuBarHeight = NSStatusBar.system.thickness
    private let playAreaWidth: CGFloat
    private let menuBarWidth: CGFloat

    init(playAreaWidth: CGFloat = 240) {
        self.playAreaWidth = playAreaWidth
        self.menuBarWidth = NSScreen.main?.frame.width ?? playAreaWidth
    }

    /// Scale sprites so they fit comfortably inside the menu bar.
    private var spriteSize: CGSize {
        let targetHeight = max(min(menuBarHeight - 2, 26), 18)
        let scale = targetHeight / baseSpriteSize.height
        return CGSize(width: baseSpriteSize.width * scale, height: targetHeight)
    }

    private var playAreaHeight: CGFloat {
        menuBarHeight
    }

    private func advanceBehavior(now: Date) {
        if now >= behaviorDeadline {
            let (next, duration) = chooseNextBehavior()
            behavior = next
            behaviorDeadline = now.addingTimeInterval(duration)
        }
    }

    private func chooseNextBehavior() -> (CatBehavior, TimeInterval) {
        let roll = Double.random(in: 0...1)
        let behavior: CatBehavior
        switch roll {
        case ..<0.25: behavior = .walk
        case ..<0.5:  behavior = .sit
        case ..<0.85: behavior = .look
        default:      behavior = .nap
        }
        let duration = behaviorDuration(behavior)
        return (behavior, duration)
    }

    private func behaviorDuration(_ behavior: CatBehavior) -> TimeInterval {
        switch behavior {
        case .walk: return Double.random(in: 5...8)
        case .sit:  return Double.random(in: 6...10)
        case .look: return Double.random(in: 6...10)
        case .nap:  return Double.random(in: 10...16)
        }
    }

    private func applyBehaviorSpeed() {
        if isHovered {
            physics.setSpeedMultiplier(0)
            return
        }
        guard viewModel.mood == .normal else {
            physics.setSpeedMultiplier(viewModel.speedMultiplier)
            return
        }
        let behaviorMultiplier: Double
        switch behavior {
        case .walk: behaviorMultiplier = 1.0
        case .sit, .look, .nap: behaviorMultiplier = 0.0
        }
        let multiplier = viewModel.speedMultiplier * behaviorMultiplier
        physics.setSpeedMultiplier(multiplier)
    }

    private var displayAnimation: SpriteAnimation {
        if isHovered {
            return MochiViewModel.rollAnimation
        }
        switch viewModel.mood {
        case .sleeping:
            return MochiViewModel.sleepAnimation
        case .carrying:
            return MochiViewModel.bagAnimation
        case .sweating:
            return MochiViewModel.sweatAnimation
        case .chonky:
            return MochiViewModel.chonkAnimation
        case .normal:
            switch behavior {
            case .walk:
                return MochiViewModel.walkAnimation
            case .sit:
                return MochiViewModel.sitAnimation
            case .look:
                return MochiViewModel.lookAnimation
            case .nap:
                return MochiViewModel.sleepAnimation
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let areaWidth = playAreaWidth
            let travelWidth = max(menuBarWidth - spriteSize.width, 1)
            let animation = displayAnimation

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                MochiOverlayView(
                    animation: animation,
                    spriteSize: spriteSize,
                    menuBarHeight: menuBarHeight,
                    positionX: physics.positionX,
                    hangOffset: 0,
                    spriteContent: spriteSpriteView
                )
                .frame(width: areaWidth, height: playAreaHeight, alignment: .topLeading)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .background(Color.clear)
            .onAppear {
                physics.updateBounds(width: travelWidth)
                lastTick = .now
                behaviorDeadline = .now
                viewModel.start()
                overlayBridge.movePet(toX: physics.positionX)
            }
            .onReceive(timer) { date in
                let dt = date.timeIntervalSince(lastTick)
                lastTick = date
                advanceBehavior(now: date)
                physics.updateBounds(width: travelWidth)
                applyBehaviorSpeed()
                physics.step(dt: dt)
                overlayBridge.movePet(toX: physics.positionX)
            }
            .onDisappear {
                viewModel.stop()
            }
        }
        .background(Color.clear)
        .ignoresSafeArea()
    }

    private func spriteSpriteView(frame: SpriteFrame) -> some View {
        ZStack {
            let facingLeft = physics.velocityX < 0
            if let image = spriteImage(named: frame.imageName) {
                image
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: spriteSize.width, height: spriteSize.height, alignment: .bottom)
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1, anchor: .center)
                    .contentShape(Rectangle())
                    .onTapGesture { showSettings.toggle() }
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.18)) {
                            isHovered = hovering
                        }
                    }
                    .popover(isPresented: $showSettings, arrowEdge: .top, content: settingsContent)
                    .overlay(alignment: .topLeading) {
                        if isHovered {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.pink)
                                .padding(.top, -4)
                                .padding(.leading, -4)
                                .transition(.opacity.combined(with: .scale))
                                .animation(.easeOut(duration: 0.2), value: isHovered)
                        }
                    }
            } else {
                Text("Sprite missing")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.red)
                    .frame(width: spriteSize.width, height: spriteSize.height)
            }
        }
        .frame(width: spriteSize.width, height: spriteSize.height)
    }

    /// Loads sprite by name from the module bundle; returns nil if missing.
    private func spriteImage(named name: String) -> Image? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let nsImage = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: nsImage)
    }

    private func settingsContent() -> some View {
        SettingsPopoverView(
            clickThrough: $overlayBridge.clickThrough,
            stats: viewModel.stats,
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
