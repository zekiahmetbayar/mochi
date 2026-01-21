import XCTest
@testable import MochiCore

final class OverlayGeometryTests: XCTestCase {
    func testFrameComputesTopAnchoredOverlay() {
        let frame = OverlayGeometry.computeFrame(
            screenWidth: 1440,
            screenHeight: 900,
            menuBarHeight: 28,
            petHeight: 32,
            petOverlap: 6
        )
        XCTAssertEqual(frame.width, 1440)
        XCTAssertEqual(frame.height, 54) // 28 + 32 - 6
        XCTAssertEqual(frame.y, 846)     // 900 - 54
        XCTAssertEqual(frame.x, 0)
    }

    func testOverlapDoesNotExceedPetHeight() {
        let frame = OverlayGeometry.computeFrame(
            screenWidth: 1920,
            screenHeight: 1080,
            menuBarHeight: 24,
            petHeight: 16,
            petOverlap: 40 // should clamp to petHeight
        )
        XCTAssertEqual(frame.height, 24) // 24 + 16 - 16
        XCTAssertEqual(frame.y, 1056)
    }

    func testNegativeInputsClampToZero() {
        let frame = OverlayGeometry.computeFrame(
            screenWidth: 1000,
            screenHeight: 600,
            menuBarHeight: -10,
            petHeight: -20,
            petOverlap: -5
        )
        XCTAssertEqual(frame.height, 0)
        XCTAssertEqual(frame.y, 600)
    }

    func testSpriteOriginAlignsToMenuBarBaseline() {
        let y = OverlayGeometry.computeSpriteOriginY(
            menuBarHeight: 24,
            spriteHeight: 60,
            hangDown: 0
        )
        // Baseline at 24, sprite height 60 => top should sit at -36 but clamped to 0.
        XCTAssertEqual(y, 0)
    }

    func testSpriteOriginAllowsHangDown() {
        let y = OverlayGeometry.computeSpriteOriginY(
            menuBarHeight: 24,
            spriteHeight: 40,
            hangDown: 10
        )
        // Without hang: -16 => clamped to 0; with hang 10 => still 0.
        XCTAssertEqual(y, 0)

        let y2 = OverlayGeometry.computeSpriteOriginY(
            menuBarHeight: 80,
            spriteHeight: 40,
            hangDown: 12
        )
        // Baseline at 80: top at 40, plus hang 12 => 52.
        XCTAssertEqual(y2, 52)
    }
}
