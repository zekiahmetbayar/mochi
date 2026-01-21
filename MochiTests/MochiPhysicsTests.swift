import XCTest
@testable import MochiCore

final class MochiPhysicsTests: XCTestCase {
    func testClampAtBounds() {
        var physics = MochiPhysics(boundsWidth: 100, seed: 1, speed: 200)
        physics.timeUntilTurn = 10 // avoid random turn during test
        physics.positionX = 5
        physics.velocityX = -300
        physics.step(dt: 1.0)
        XCTAssertEqual(physics.positionX, 0, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(physics.velocityX, 0)
    }

    func testDeterministicMovementWithSeed() {
        var physics = MochiPhysics(boundsWidth: 200, seed: 1234, speed: 50)
        var positions: [Double] = []
        for _ in 0..<5 {
            physics.step(dt: 0.5)
            positions.append(physics.positionX)
        }
        XCTAssertEqual(positions.count, 5)
        XCTAssertEqual(positions[0], 125.0, accuracy: 0.1)
        XCTAssertEqual(positions[1], 150.0, accuracy: 0.1)
        XCTAssertLessThanOrEqual(positions.max() ?? 0, 200.0)
        XCTAssertGreaterThanOrEqual(positions.min() ?? 0, 0.0)
    }
}
