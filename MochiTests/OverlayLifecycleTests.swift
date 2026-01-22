import XCTest
@testable import MochiCore

final class OverlayLifecycleTests: XCTestCase {
    private final class MockOverlayController: OverlayControlling {
        var showCount = 0
        var hideCount = 0
        var moves: [Double] = []
        func show() { showCount += 1 }
        func hide() { hideCount += 1 }
        func move(toX: Double) { moves.append(toX) }
    }

    func testStartShowsOverlayOnce() {
        let mock = MockOverlayController()
        let lifecycle = OverlayLifecycle(controller: mock)
        XCTAssertEqual(lifecycle.state, .idle)
        XCTAssertEqual(lifecycle.start(), .shown)
        XCTAssertEqual(mock.showCount, 1)
        // second start should be a no-op
        XCTAssertEqual(lifecycle.start(), .shown)
        XCTAssertEqual(mock.showCount, 1)
    }

    func testStopHidesWhenShown() {
        let mock = MockOverlayController()
        let lifecycle = OverlayLifecycle(controller: mock)
        _ = lifecycle.start()
        XCTAssertEqual(lifecycle.stop(), .idle)
        XCTAssertEqual(mock.hideCount, 1)
        // second stop no-op
        XCTAssertEqual(lifecycle.stop(), .idle)
        XCTAssertEqual(mock.hideCount, 1)
    }

    func testStartNoControllerKeepsIdle() {
        let lifecycle = OverlayLifecycle(controller: nil)
        XCTAssertEqual(lifecycle.start(), .idle)
    }
}
