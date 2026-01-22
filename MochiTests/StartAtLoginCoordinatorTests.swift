import XCTest
@testable import MochiCore

final class StartAtLoginCoordinatorTests: XCTestCase {
    private final class MockController: StartAtLoginControlling {
        var isSupported: Bool = true
        var isEnabled: Bool = false
        var setCalls: [Bool] = []
        var succeed = true

        func setEnabled(_ enable: Bool) -> Bool {
            setCalls.append(enable)
            isEnabled = enable
            return succeed
        }
    }

    func testApplySkipsWhenAlreadySet() {
        let mock = MockController()
        mock.isEnabled = true
        let coord = StartAtLoginCoordinator(controller: mock)
        let result = coord.apply(desired: true)
        XCTAssertTrue(result)
        XCTAssertTrue(mock.setCalls.isEmpty)
    }

    func testApplyCallsController() {
        let mock = MockController()
        let coord = StartAtLoginCoordinator(controller: mock)
        let result = coord.apply(desired: true)
        XCTAssertTrue(result)
        XCTAssertEqual(mock.setCalls, [true])
        XCTAssertTrue(mock.isEnabled)
    }

    func testApplyFailsWhenUnsupported() {
        let mock = MockController()
        mock.isSupported = false
        let coord = StartAtLoginCoordinator(controller: mock)
        let result = coord.apply(desired: true)
        XCTAssertFalse(result)
        XCTAssertTrue(mock.setCalls.isEmpty)
    }
}
