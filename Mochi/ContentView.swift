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

private enum PortalPhase {
    case idle
    case entering
    case exiting
}

/// Debug toggle: forces continuous edge-bouncing walking so portal teleport is easy to test.
private let continuousWalkTestMode = false

struct ContentView: View {
    @EnvironmentObject private var overlayBridge: OverlayBridge
    // Random direction-flips are disabled; behavior layer picks walk targets.
    @State private var physics = MochiPhysics(
        boundsWidth: 400,
        seed: 99,
        speed: continuousWalkTestMode ? 60 : 28,
        minTurnInterval: 9_999,
        maxTurnInterval: 9_999
    )
    @State private var lastTick: Date = .now
    @State private var showSettings = false
    @StateObject private var viewModel = MochiViewModel()
    @StateObject private var settings = SettingsViewModel()
    @State private var behavior: CatBehavior = .walk
    @State private var behaviorDeadline: Date = .now
    @State private var isHovered: Bool = false
    @State private var pinnedAnchorX: Double?
    @State private var nextPinnedAnchorRefresh: Date = .distantPast
    @State private var isResolvingPinnedAnchor: Bool = false
    @State private var stationaryBehaviorIndex: Int = 0
    @State private var walkTargetX: Double = 0
    @State private var walkArrivalTolerance: Double = 4
    @State private var dashEndTime: Date = .distantPast
    @State private var dashDirection: Double = 1
    @State private var rightClickMonitor: Any?
    private let dashSpeedMultiplier: Double = 3.5
    private let dashDuration: TimeInterval = 1.0
    @State private var portalPhase: PortalPhase = .idle
    @State private var portalDeadline: Date = .distantPast
    @State private var portalCooldownUntil: Date = .distantPast
    @State private var portalSavedSpeedMul: Double = 1.0
    @State private var portalDirection: Double = 1.0
    @State private var portalStart: Date = .distantPast
    @State private var portalAnim: PortalAnim = .idle
    private let portalEnteringDuration: TimeInterval = 0.55
    private let portalExitingDuration: TimeInterval = 0.55
    @StateObject private var ticker = AnimationTicker(fps: 24, leewayMilliseconds: 12)
    private let inactiveFPS: Double = 12
    private let baseSpriteSize = CGSize(width: 64, height: 32)
    private let menuBarHeight = NSStatusBar.system.thickness
    private let playAreaWidth: CGFloat
    private let menuBarWidth: CGFloat
    private let stationaryBehaviors: [CatBehavior] = [.sit, .look, .nap]

    init(playAreaWidth: CGFloat = 240) {
        self.playAreaWidth = playAreaWidth
        self.menuBarWidth = NSScreen.main?.frame.width ?? playAreaWidth
    }

    /// Scale sprites so they fit comfortably inside the menu bar.
    private var spriteSize: CGSize {
        let targetHeight = max(min(menuBarHeight - 2, 26), 18) * 1.15
        let maxHeight = min(menuBarHeight * 2.8, 72)
        let desiredHeight = min(targetHeight * settings.state.scale, maxHeight)
        let scale = desiredHeight / baseSpriteSize.height
        return CGSize(width: baseSpriteSize.width * scale, height: desiredHeight)
    }

    private var playAreaHeight: CGFloat {
        max(menuBarHeight, spriteSize.height) + 10
    }

    private func advanceBehavior(now: Date, travelWidth: Double) {
        if continuousWalkTestMode {
            behavior = .walk
            behaviorDeadline = now.addingTimeInterval(60)
            return
        }
        let shouldAdvance: Bool
        if behavior == .walk {
            // Advance when reached target OR safety timeout fired.
            let reached = abs(physics.positionX - walkTargetX) <= walkArrivalTolerance
            shouldAdvance = reached || now >= behaviorDeadline
        } else {
            shouldAdvance = now >= behaviorDeadline
        }
        guard shouldAdvance else { return }
        transition(to: pickNextBehavior(after: behavior), now: now, travelWidth: travelWidth)
    }

    /// Markov-ish transition table chosen to feel like an actual cat:
    /// movement begets curiosity (look), curiosity often settles into sitting,
    /// sitting may deepen into a nap, and naps usually end with a walk.
    private func pickNextBehavior(after current: CatBehavior) -> CatBehavior {
        let r = Double.random(in: 0...1)
        switch current {
        case .walk:
            if r < 0.55 { return .look }   // arrived somewhere → scan around
            if r < 0.80 { return .sit }    // sit and chill
            if r < 0.95 { return .walk }   // change of mind, new destination
            return .nap
        case .look:
            if r < 0.50 { return .walk }   // saw something interesting
            if r < 0.85 { return .sit }    // calm down
            return .look                   // keep scanning a different angle
        case .sit:
            if r < 0.40 { return .walk }   // restless
            if r < 0.70 { return .look }   // glance around
            if r < 0.90 { return .nap }    // drift off
            return .sit                    // settle deeper
        case .nap:
            if r < 0.65 { return .walk }   // refreshed → stretch & roam
            if r < 0.85 { return .look }   // groggy glance
            return .sit
        }
    }

    private func transition(to next: CatBehavior, now: Date, travelWidth: Double) {
        behavior = next
        if next == .walk {
            walkTargetX = pickWalkTarget(travelWidth: travelWidth)
            // Safety timeout: ~ distance / speed * 2, clamped to a sane range.
            let distance = abs(walkTargetX - physics.positionX)
            let estimate = max(distance / max(physics.speed, 1), 3) * 2
            behaviorDeadline = now.addingTimeInterval(min(max(estimate, 4), 18))
        } else {
            behaviorDeadline = now.addingTimeInterval(behaviorDuration(next))
        }
    }

    private func pickWalkTarget(travelWidth: Double) -> Double {
        guard travelWidth > 1 else { return physics.positionX }
        // Pick a destination far enough from current position to feel intentional,
        // not a tiny twitch. Try a few candidates then fall back to a far side.
        let minDistance = max(travelWidth * 0.25, 60)
        for _ in 0..<6 {
            let candidate = Double.random(in: 0...travelWidth)
            if abs(candidate - physics.positionX) >= minDistance {
                return candidate
            }
        }
        return physics.positionX > travelWidth / 2 ? travelWidth * 0.15 : travelWidth * 0.85
    }

    private func behaviorDuration(_ behavior: CatBehavior) -> TimeInterval {
        switch behavior {
        case .walk: return Double.random(in: 6...10)   // unused for walk (target-based)
        case .sit:  return Double.random(in: 6...12)
        case .look: return Double.random(in: 2.5...5)  // short curiosity beat
        case .nap:  return Double.random(in: 18...28)
        }
    }

    private func nextStationaryBehavior() -> CatBehavior {
        let behavior = stationaryBehaviors[stationaryBehaviorIndex % stationaryBehaviors.count]
        stationaryBehaviorIndex = (stationaryBehaviorIndex + 1) % stationaryBehaviors.count
        return behavior
    }

    private func resetStationaryBehaviorCycle(now: Date) {
        stationaryBehaviorIndex = 0
        let next = nextStationaryBehavior()
        behavior = next
        behaviorDeadline = now.addingTimeInterval(behaviorDuration(next))
    }

    private func requestPinnedAnchor(travelWidth: CGFloat, now: Date) {
        guard !isResolvingPinnedAnchor else { return }
        isResolvingPinnedAnchor = true
        // Throttle while probe measurement is in flight.
        nextPinnedAnchorRefresh = now.addingTimeInterval(0.3)

        overlayBridge.resolvePreferredPinnedX { raw in
            DispatchQueue.main.async {
                isResolvingPinnedAnchor = false
                guard settings.state.pinToMenuGap else { return }
                if let raw {
                    pinnedAnchorX = min(max(raw, 0), Double(travelWidth))
                    nextPinnedAnchorRefresh = Date().addingTimeInterval(2.0)
                } else {
                    if pinnedAnchorX == nil {
                        pinnedAnchorX = min(max(physics.positionX, 0), Double(travelWidth))
                    }
                    nextPinnedAnchorRefresh = Date().addingTimeInterval(0.8)
                }
            }
        }
    }

    private func applyPinnedMode(now: Date, travelWidth: CGFloat) {
        if pinnedAnchorX == nil || now >= nextPinnedAnchorRefresh {
            requestPinnedAnchor(travelWidth: travelWidth, now: now)
        }

        if now >= behaviorDeadline {
            let next = nextStationaryBehavior()
            behavior = next
            behaviorDeadline = now.addingTimeInterval(behaviorDuration(next))
        }

        physics.updateBounds(width: travelWidth)
        let fallback = min(max(physics.positionX, 0), Double(travelWidth))
        let target = min(max(pinnedAnchorX ?? fallback, 0), Double(travelWidth))
        physics.positionX = target
        physics.setSpeedMultiplier(0)
        overlayBridge.movePet(toX: target)
    }

    /// Drives the notch portal teleport: detects when the sprite crosses the notch edge,
    /// freezes physics while playing entry/exit portal animations, and teleports across.
    private func updatePortal(now: Date) {
        // Keep portals fully outside the notch: offset sprite center by half-portal
        // width plus a small breathing margin on each side.
        let portalMargin = spriteSize.height * 0.6 + 6

        switch portalPhase {
        case .idle:
            guard now >= portalCooldownUntil else { return }
            guard let notch = overlayBridge.notchLocalRange() else { return }
            let halfOverlay = overlayBridge.overlayWidth / 2
            let spriteCenter = physics.positionX + halfOverlay
            let entryLeft = notch.left - portalMargin   // trigger point for right-bound travel
            let entryRight = notch.right + portalMargin // trigger point for left-bound travel
            let goingRight = physics.velocityX > 0
            let goingLeft = physics.velocityX < 0
            let entering: Bool
            if goingRight {
                entering = spriteCenter >= entryLeft && spriteCenter <= entryRight
            } else if goingLeft {
                entering = spriteCenter <= entryRight && spriteCenter >= entryLeft
            } else {
                entering = false
            }
            guard entering else { return }
            portalDirection = goingRight ? 1 : -1
            portalSavedSpeedMul = physics.speedMultiplier
            physics.setSpeedMultiplier(0)
            // Snap sprite to the entry margin point so the portal sits cleanly beside the notch.
            let entryCenter = goingRight ? entryLeft : entryRight
            physics.positionX = max(0, min(entryCenter - halfOverlay, physics.boundsWidth))
            portalPhase = .entering
            portalStart = now
            portalDeadline = now.addingTimeInterval(portalEnteringDuration)

        case .entering:
            if now >= portalDeadline {
                let halfOverlay = overlayBridge.overlayWidth / 2
                if let notch = overlayBridge.notchLocalRange() {
                    // Emerge fully past the far notch edge.
                    let targetCenter = portalDirection > 0
                        ? notch.right + portalMargin
                        : notch.left - portalMargin
                    physics.positionX = max(0, min(targetCenter - halfOverlay, physics.boundsWidth))
                }
                portalPhase = .exiting
                portalStart = now
                portalDeadline = now.addingTimeInterval(portalExitingDuration)
            }

        case .exiting:
            if now >= portalDeadline {
                physics.setSpeedMultiplier(portalSavedSpeedMul == 0 ? 1 : portalSavedSpeedMul)
                // Preserve travel direction (setSpeedMultiplier keeps current sign).
                if (physics.velocityX > 0) != (portalDirection > 0) {
                    physics.velocityX = portalDirection * abs(physics.velocityX)
                }
                portalPhase = .idle
                portalCooldownUntil = now.addingTimeInterval(0.6)
            }
        }
    }

    private func applyBehaviorSpeed() {
        if settings.state.pinToMenuGap {
            physics.setSpeedMultiplier(0)
            return
        }
        // Dash overrides everything else (including hover freeze) for its 1s window.
        if Date() < dashEndTime {
            physics.velocityX = dashDirection * physics.speed * dashSpeedMultiplier
            physics.speedMultiplier = dashSpeedMultiplier
            return
        }
        if isHovered {
            physics.setSpeedMultiplier(0)
            return
        }
        // Mood overrides (carrying/sleeping/sweating/chonky) use single-frame sprites,
        // so let the cat stand still in pose instead of sliding across the menu bar.
        guard viewModel.mood == .normal else {
            physics.setSpeedMultiplier(0)
            return
        }
        switch behavior {
        case .walk:
            // Drive direction toward the chosen target so movement looks intentional.
            let toTarget = walkTargetX - physics.positionX
            if abs(toTarget) <= walkArrivalTolerance {
                physics.setSpeedMultiplier(0)
                return
            }
            let direction = toTarget >= 0 ? 1.0 : -1.0
            physics.velocityX = direction * physics.speed * viewModel.speedMultiplier
            physics.speedMultiplier = viewModel.speedMultiplier
        case .sit, .look, .nap:
            physics.setSpeedMultiplier(0)
        }
    }

    /// Triggered by right-click on Mochi: dash for 1s toward the farther screen edge.
    private func triggerDash(travelWidth: Double) {
        guard travelWidth > 1 else { return }
        let farRight = physics.positionX < travelWidth / 2
        dashDirection = farRight ? 1 : -1
        dashEndTime = Date().addingTimeInterval(dashDuration)
        // Switch to walking visuals + aim past the far edge so the behavior layer
        // doesn't try to "arrive" before the dash window ends.
        behavior = .walk
        walkTargetX = farRight ? travelWidth : 0
        behaviorDeadline = dashEndTime.addingTimeInterval(0.5)
    }

    private var displayAnimation: SpriteAnimation {
        if Date() < dashEndTime {
            return MochiViewModel.walkAnimation
        }
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
            let travelWidth = max(menuBarWidth - playAreaWidth, 1)
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
                let now = Date()
                viewModel.start()
                ticker.start()
                overlayBridge.movePet(toX: physics.positionX)
                applySettings(settings.state)
                // Seed initial behavior so the cat starts with a purposeful walk.
                transition(to: .walk, now: now, travelWidth: Double(travelWidth))
                // Right-click on Mochi's overlay window → dash toward the farther edge.
                rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
                    if let win = event.window,
                       win === overlayBridge.controller?.window {
                        triggerDash(travelWidth: Double(travelWidth))
                        return nil
                    }
                    return event
                }
                if settings.state.pinToMenuGap {
                    pinnedAnchorX = nil
                    nextPinnedAnchorRefresh = .distantPast
                    isResolvingPinnedAnchor = false
                    resetStationaryBehaviorCycle(now: now)
                    applyPinnedMode(now: now, travelWidth: travelWidth)
                }
            }
            .onReceive(ticker.$tick) { date in
                let dt = date.timeIntervalSince(lastTick)
                lastTick = date
                if settings.state.pinToMenuGap {
                    applyPinnedMode(now: date, travelWidth: travelWidth)
                    return
                }
                advanceBehavior(now: date, travelWidth: Double(travelWidth))
                physics.updateBounds(width: travelWidth)
                applyBehaviorSpeed()
                if portalPhase != .idle {
                    physics.setSpeedMultiplier(0)
                }
                physics.step(dt: dt)
                updatePortal(now: date)
                let newAnim = portalAnimationValues(at: date)
                if newAnim != portalAnim { portalAnim = newAnim }
                overlayBridge.movePet(toX: physics.positionX)
            }
            .onDisappear {
                viewModel.stop()
                ticker.stop()
                if let monitor = rightClickMonitor {
                    NSEvent.removeMonitor(monitor)
                    rightClickMonitor = nil
                }
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
            .onChange(of: settings.state.pinToMenuGap) { pinned in
                let now = Date()
                if pinned {
                    pinnedAnchorX = nil
                    nextPinnedAnchorRefresh = .distantPast
                    isResolvingPinnedAnchor = false
                    resetStationaryBehaviorCycle(now: now)
                    applyPinnedMode(now: now, travelWidth: travelWidth)
                } else {
                    pinnedAnchorX = nil
                    nextPinnedAnchorRefresh = .distantPast
                    isResolvingPinnedAnchor = false
                    stationaryBehaviorIndex = 0
                    behavior = .walk
                    behaviorDeadline = now.addingTimeInterval(behaviorDuration(.walk))
                }
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
        let facingLeft = physics.velocityX < 0
        return ZStack {
            if let image = spriteImage(named: frame.imageName) {
                image
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: spriteSize.width, height: spriteSize.height, alignment: .bottom)
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1, anchor: .center)
                    .scaleEffect(portalAnim.catScale, anchor: .bottom)
                    .opacity(portalAnim.catOpacity)
                    .contentShape(Rectangle())
                    .onTapGesture { showSettings.toggle() }
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.18)) {
                            isHovered = hovering
                        }
                    }
                    .popover(isPresented: $showSettings, arrowEdge: .top, content: settingsContent)
                    .overlay(alignment: .top) {
                        if isHovered {
                            FloatingHearts()
                                .frame(width: spriteSize.width, height: spriteSize.height + 14)
                                .offset(y: -(spriteSize.height + 8))
                                .allowsHitTesting(false)
                                .transition(.opacity)
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
            portalOverlay(anim: portalAnim)
        }
        .frame(width: spriteSize.width, height: spriteSize.height)
    }

    @ViewBuilder
    private func portalOverlay(anim: PortalAnim) -> some View {
        if let frameName = anim.portalFrameName, let img = spriteImage(named: frameName) {
            let h = spriteSize.height * 1.7
            let w = h * (286.0 / 359.0) // canvas aspect from the sprite sheet
            img
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .allowsHitTesting(false)
        }
    }

    private struct PortalAnim: Equatable {
        let catOpacity: Double
        let catScale: Double
        let portalFrameName: String?
        static let idle = PortalAnim(catOpacity: 1, catScale: 1, portalFrameName: nil)
    }

    private func portalAnimationValues(at date: Date) -> PortalAnim {
        switch portalPhase {
        case .idle:
            return .idle

        case .entering:
            let p = clamp01(date.timeIntervalSince(portalStart) / portalEnteringDuration)
            // Portal opens (frames 0→5) over first 50% of the phase, then holds open.
            let openP = clamp01(p / 0.5)
            let frame = min(5, Int(openP * 6))
            // Cat keeps standing while portal opens, then gets sucked in.
            let catFade = easeIn(clamp01((p - 0.5) / 0.5))
            return PortalAnim(
                catOpacity: 1 - catFade,
                catScale: 1 - catFade * 0.65,
                portalFrameName: "mochi_portal_in_\(frame)"
            )

        case .exiting:
            let p = clamp01(date.timeIntervalSince(portalStart) / portalExitingDuration)
            // Portal holds open during first 50%, then closes (frames 5→0).
            let frame: Int
            if p < 0.5 {
                frame = 5
            } else {
                let closeP = clamp01((p - 0.5) / 0.5)
                frame = max(0, 5 - Int(closeP * 6))
            }
            // Cat emerges and grows during the hold-open window.
            let catReveal = easeOut(clamp01(p / 0.5))
            return PortalAnim(
                catOpacity: catReveal,
                catScale: 0.35 + catReveal * 0.65,
                portalFrameName: "mochi_portal_out_\(frame)"
            )
        }
    }

    private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
    private func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }
    private func easeIn(_ t: Double) -> Double { pow(t, 2) }

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
            mood: viewModel.mood,
            startAtLoginSupported: settings.startAtLoginSupported,
            onQuit: { overlayBridge.quitApp() }
        )
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
    let mood: MochiMood
    let startAtLoginSupported: Bool
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statsRow
            section(title: "General") {
                SettingRow(title: "Click-through overlay",
                           subtitle: "Let clicks pass to apps below") {
                    Toggle("", isOn: $state.clickThrough).labelsHidden()
                }
                SettingRow(title: "Pin to menu gap",
                           subtitle: "Park Mochi next to your status icons") {
                    Toggle("", isOn: $state.pinToMenuGap).labelsHidden()
                }
                SettingRow(title: "Start at login",
                           subtitle: startAtLoginSupported ? nil : "Not supported in this build") {
                    Toggle("", isOn: $state.startAtLogin)
                        .labelsHidden()
                        .disabled(!startAtLoginSupported)
                }
                SettingRow(title: "Show debug overlay") {
                    Toggle("", isOn: $state.showDebugOverlay).labelsHidden()
                }
            }
            section(title: "Appearance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.system(size: 12))
                    Picker("", selection: $state.scale) {
                        Label("S", systemImage: "smallcircle.filled.circle").tag(1.0)
                        Label("M", systemImage: "circle.circle.fill").tag(1.5)
                        Label("L", systemImage: "largecircle.fill.circle").tag(2.0)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }
            section(title: "Reactions") {
                SliderRow(label: "CPU sweat",
                          systemImage: "thermometer.medium",
                          value: $state.cpuThreshold,
                          range: 50...90,
                          format: { String(format: "%.0f%%", $0) })
                SliderRow(label: "RAM chonk",
                          systemImage: "memorychip",
                          value: $state.ramThreshold,
                          range: 60...95,
                          format: { String(format: "%.0f%%", $0) })
                SliderRow(label: "Heavy download",
                          systemImage: "arrow.down.circle",
                          value: $state.downloadThreshold,
                          range: 50_000...400_000,
                          format: Self.formatBytesPerSecond)
            }
            Divider().opacity(0.4)
            Button(role: .destructive, action: onQuit) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Quit Mochi")
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 280)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.9), Color.pink.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Mochi")
                    .font(.system(size: 14, weight: .semibold))
                Text(moodSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var moodSubtitle: String {
        switch mood {
        case .normal:   return "Lurking happily"
        case .sleeping: return "Taking a nap"
        case .carrying: return "Holding your download"
        case .sweating: return "CPU is toasty"
        case .chonky:   return "Memory's getting full"
        }
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatChip(icon: "cpu",
                     label: "CPU",
                     value: "\(Int(stats.cpuPercent))%",
                     tint: stats.cpuHot ? .orange : .secondary)
            StatChip(icon: "memorychip",
                     label: "RAM",
                     value: "\(Int(stats.ramUsedPercent))%",
                     tint: .secondary)
            StatChip(icon: stats.networkReachable ? "arrow.down" : "wifi.slash",
                     label: stats.networkReachable ? "DL" : "OFFLINE",
                     value: stats.networkReachable
                        ? Self.formatBytesPerSecond(stats.downloadRate)
                        : "—",
                     tint: stats.downloadHeavy ? .blue : .secondary)
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
        }
    }

    // MARK: Formatting

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

    static func formatBytesPerSecond(_ bytes: Double) -> String {
        "\(formatBytes(bytes))/s"
    }
}

// MARK: Components

private struct SettingRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .frame(minHeight: 28)
    }
}

private struct StatChip: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.4)
            }
            .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.4))
        )
    }
}

private struct SliderRow: View {
    let label: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(label)
                    .font(.system(size: 12))
                Spacer()
                Text(format(value))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
                .controlSize(.mini)
        }
    }
}

/// Three small pink hearts rising from the bottom to the top of their frame in a continuous loop.
private struct FloatingHearts: View {
    private let count = 3
    private let period: Double = 1.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<count, id: \.self) { i in
                        heart(index: i, time: t, size: geo.size)
                    }
                }
            }
        }
    }

    private func heart(index: Int, time: Double, size: CGSize) -> some View {
        let phase = ((time / period) + Double(index) / Double(count))
            .truncatingRemainder(dividingBy: 1.0)
        let progress = CGFloat(phase)
        let xJitter = CGFloat(sin(phase * .pi * 2 + Double(index)) * 4)
        let scale = CGFloat(0.7 + 0.3 * sin(phase * .pi))
        let x = size.width / 2 + xJitter
        let y = size.height * (1 - progress)
        return Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.pink)
            .opacity(heartOpacity(progress: progress))
            .scaleEffect(scale)
            .position(x: x, y: y)
    }

    private func heartOpacity(progress: CGFloat) -> Double {
        if progress < 0.2 {
            return Double(progress / 0.2)
        } else if progress > 0.75 {
            return Double((1 - progress) / 0.25)
        }
        return 1
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
