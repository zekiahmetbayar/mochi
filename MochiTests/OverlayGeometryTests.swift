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
}
