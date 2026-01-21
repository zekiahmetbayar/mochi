#if os(macOS)
import SwiftUI
import MochiCore

/// SwiftUI view that advances through a `SpriteAnimation` over time.
public struct SpriteRendererView<Content: View>: View {
    private let animation: SpriteAnimation
    private let renderer: (SpriteFrame) -> Content
    @State private var startDate = Date()

    public init(animation: SpriteAnimation, @ViewBuilder renderer: @escaping (SpriteFrame) -> Content) {
        self.animation = animation
        self.renderer = renderer
    }

    public var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let index = animation.frameIndex(at: elapsed)
            if let frame = animation.frame(at: index) {
                renderer(frame)
            } else {
                Color.clear
            }
        }
        .onAppear { startDate = Date() }
    }
}
#endif
