import XCTest
@testable import MochiApp
@testable import MochiCore

#if os(macOS)
final class MochiViewModelAnimationsTests: XCTestCase {
    @MainActor
    func testWalkAnimationHasFourFrames() {
        XCTAssertEqual(MochiViewModel.walkAnimation.frames.count, 4)
    }

    @MainActor
    func testRollAnimationLoops() {
        let roll = MochiViewModel.rollAnimation
        XCTAssertTrue(roll.loop)
        XCTAssertEqual(roll.frames.count, 4)
        XCTAssertEqual(roll.frames.first?.imageName, "mochi_roll_0")
    }
}
#endif
