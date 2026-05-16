#if os(macOS)
import SwiftUI
import MochiCore

/// Renders Mochi anchored to the menu bar baseline with optional hanging offset.
struct MochiOverlayView<SpriteContent: View>: View {
    let animation: SpriteAnimation
    let spriteSize: CGSize
    let menuBarHeight: CGFloat
    let positionX: CGFloat   // left edge in points
    let hangOffset: CGFloat
    let spriteContent: (SpriteFrame) -> SpriteContent

    var body: some View {
        GeometryReader { geo in
            let clampedLeft = clampLeft(in: geo.size.width)
            let spriteY = computeY(containerHeight: geo.size.height)
            SpriteRendererView(animation: animation, renderer: spriteContent)
                .frame(width: spriteSize.width, height: spriteSize.height)
                .position(
                    x: clampedLeft + spriteSize.width / 2,
                    y: spriteY + spriteSize.height / 2
                )
                .contentShape(Rectangle())
        }
    }

    private func clampLeft(in width: CGFloat) -> CGFloat {
        let maxLeft = max(width - spriteSize.width, 0)
        return min(max(positionX, 0), maxLeft)
    }

    private func computeY(containerHeight: CGFloat) -> CGFloat {
        // Keep a small top margin so the sprite's head never sits at the screen edge,
        // and a bottom margin so the feet stay visible inside the clipped play area.
        let topMargin: CGFloat = 4
        let bottomMargin: CGFloat = 4
        let raw = OverlayGeometry.computeSpriteOriginY(
            menuBarHeight: Double(menuBarHeight),
            spriteHeight: Double(spriteSize.height),
            hangDown: Double(hangOffset)
        )
        let maxY = max(containerHeight - spriteSize.height - bottomMargin, topMargin)
        return min(max(topMargin, CGFloat(raw)), maxY)
    }
}
#endif
