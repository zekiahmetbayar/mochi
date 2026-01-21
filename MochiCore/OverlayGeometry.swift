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
}
