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
    @StateObject private var settings = SettingsViewModel()
    @State private var behavior: CatBehavior = .walk
    @State private var behaviorDeadline: Date = .now
    @State private var isHovered: Bool = false
    @StateObject private var ticker = AnimationTicker(fps: 24, leewayMilliseconds: 12)
    private let inactiveFPS: Double = 12
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
        // Allow upscale but clamp to ~2.5x menu bar height (up to 64px) to avoid spill.
        let maxHeight = min(menuBarHeight * 2.5, 64)
        let desiredHeight = min(targetHeight * settings.state.scale, maxHeight)
        let scale = desiredHeight / baseSpriteSize.height
        return CGSize(width: baseSpriteSize.width * scale, height: desiredHeight)
    }

    private var playAreaHeight: CGFloat {
        max(menuBarHeight, spriteSize.height)
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
                ticker.start()
                overlayBridge.movePet(toX: physics.positionX)
                applySettings(settings.state)
            }
            .onReceive(ticker.$tick) { date in
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
                ticker.stop()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                ticker.setFPS(24)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                ticker.setFPS(inactiveFPS)
            }
            .onChange(of: settings.state) { newValue in
                applySettings(newValue)
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.showOnboarding {
                    OnboardingBubble(dismiss: {
                        viewModel.dismissOnboarding()
                    })
                    .offset(x: -spriteSize.width * 0.5,
                            y: -spriteSize.height * 0.6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
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
                        if settings.state.showDebugOverlay {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CPU \(Int(viewModel.stats.cpuPercent))%")
                                Text("RAM \(Int(viewModel.stats.ramUsedPercent))%")
                                Text("DL \(formatBytes(viewModel.stats.downloadRate))/s")
                            }
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                            .offset(x: 4, y: -6)
                            .transition(.opacity)
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
            state: $settings.state,
            stats: viewModel.stats,
            startAtLoginSupported: settings.startAtLoginSupported,
            onQuit: { overlayBridge.quitApp() }
        )
        .padding()
    }

    private func applySettings(_ state: SettingsState) {
        overlayBridge.clickThrough = state.clickThrough
        viewModel.applySettings(state)
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

struct SettingsPopoverView: View {
    @Binding var state: SettingsState
    let stats: SystemStats
    let startAtLoginSupported: Bool
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.headline)
            Toggle("Click-through overlay", isOn: $state.clickThrough)
            Toggle("Show debug overlay", isOn: $state.showDebugOverlay)
            Toggle("Start at login", isOn: $state.startAtLogin)
                .disabled(!startAtLoginSupported)
            if !startAtLoginSupported {
                Text("Start at login not supported in this build.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Picker("Scale", selection: $state.scale) {
                Text("1×").tag(1.0)
                Text("1.5×").tag(1.5)
                Text("2×").tag(2.0)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 6) {
                Text("Thresholds")
                    .font(.subheadline).bold()
                sliderRow(label: "CPU sweat", value: $state.cpuThreshold, range: 50...90, format: "%.0f%%")
                sliderRow(label: "RAM chonk", value: $state.ramThreshold, range: 60...95, format: "%.0f%%")
                sliderRow(label: "Download bag", value: $state.downloadThreshold, range: 50_000...400_000, format: "%.0f B/s")
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug (live)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("CPU: \(Int(stats.cpuPercent))%")
                Text("CPU Hot: \(stats.cpuHot ? "On" : "Off")")
                Text("RAM: \(Int(stats.ramUsedPercent))%")
                Text("Net: \(stats.networkReachable ? "Reachable" : "Offline")")
                Text("DL: \(SettingsPopoverView.formatBytes(stats.downloadRate))/s")
                Text("Bag mode: \(stats.downloadHeavy ? "On" : "Off")")
            }
            Divider()
            Button("Quit Mochi", action: onQuit)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(width: 220)
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    static func formatBytes(_ bytes: Double) -> String {
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

private struct OnboardingBubble: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.point.up.left.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("This is Mochi!")
                    .font(.system(size: 12, weight: .semibold))
                Text("Click to open settings.")
                    .font(.system(size: 11))
                    .opacity(0.9)
            }
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(radius: 4, y: 2)
        .onTapGesture { dismiss() }
    }
}
#endif
