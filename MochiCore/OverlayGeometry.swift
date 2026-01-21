import Foundation

public enum OverlayGeometry {
    public struct Frame: Equatable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double
    }

    /// Computes an overlay frame aligned to the top of the given screen metrics.
    /// - Parameters:
    ///   - screenWidth: Screen width in points.
    ///   - screenHeight: Screen height in points.
    ///   - menuBarHeight: Height of the menu bar in points.
    ///   - petHeight: Desired pet height in points.
    ///   - petOverlap: Portion of the pet height allowed to overlap below the menu bar.
    /// - Returns: A frame covering the screen width and hugging the top edge.
    public static func computeFrame(
        screenWidth: Double,
        screenHeight: Double,
        menuBarHeight: Double,
        petHeight: Double,
        petOverlap: Double = 0
    ) -> Frame {
        let clampedMenuBar = max(menuBarHeight, 0)
        let clampedPet = max(petHeight, 0)
        let clampedOverlap = max(0, min(petOverlap, clampedPet))
        let totalHeight = clampedMenuBar + clampedPet - clampedOverlap
        let yOrigin = screenHeight - totalHeight
        return Frame(x: 0, y: yOrigin, width: screenWidth, height: totalHeight)
    }

    /// Computes the sprite's top-left Y origin so its bottom aligns with the menu bar baseline,
    /// allowing an optional downward "hang" offset.
    /// - Parameters:
    ///   - menuBarHeight: Menu bar height in points.
    ///   - spriteHeight: Sprite height in points.
    ///   - hangDown: Additional offset in points to drop the sprite below the baseline.
    /// - Returns: The Y origin (from the top of the overlay) clamped to be non-negative.
    public static func computeSpriteOriginY(
        menuBarHeight: Double,
        spriteHeight: Double,
        hangDown: Double = 0
    ) -> Double {
        let clampedMenu = max(menuBarHeight, 0)
        let clampedSprite = max(spriteHeight, 0)
        let clampedHang = max(hangDown, 0)
        let origin = clampedMenu - clampedSprite + clampedHang
        return max(origin, 0)
    }
}
