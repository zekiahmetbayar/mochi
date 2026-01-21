import XCTest
@testable import MochiCore

final class SpriteAnimationTests: XCTestCase {
    func testFrameIndexLoops() {
        let animation = SpriteAnimation(
            frames: [
                SpriteFrame(imageName: "a", duration: 0.1),
                SpriteFrame(imageName: "b", duration: 0.1),
                SpriteFrame(imageName: "c", duration: 0.2)
            ],
            loop: true
        )

        XCTAssertEqual(animation.frameIndex(at: 0.0), 0)
        XCTAssertEqual(animation.frameIndex(at: 0.05), 0)
        XCTAssertEqual(animation.frameIndex(at: 0.11), 1)
        XCTAssertEqual(animation.frameIndex(at: 0.21), 2)
        XCTAssertEqual(animation.frameIndex(at: 0.29), 2)
        // Looping back after 0.4s total duration
        XCTAssertEqual(animation.frameIndex(at: 0.41), 0)
    }

    func testFrameIndexClampsWhenNotLooping() {
        let animation = SpriteAnimation(
            frames: [
                SpriteFrame(imageName: "a", duration: 0.05),
                SpriteFrame(imageName: "b", duration: 0.05)
            ],
            loop: false
        )
        XCTAssertEqual(animation.frameIndex(at: 0.0), 0)
        XCTAssertEqual(animation.frameIndex(at: 0.04), 0)
        XCTAssertEqual(animation.frameIndex(at: 0.06), 1)
        XCTAssertEqual(animation.frameIndex(at: 0.20), 1) // clamps to last
    }

    func testFrameReturnsNilForEmptyAnimation() {
        let animation = SpriteAnimation(frames: [], loop: true)
        XCTAssertEqual(animation.frameIndex(at: 0.3), 0)
        XCTAssertNil(animation.frame(at: 0))
    }
}
