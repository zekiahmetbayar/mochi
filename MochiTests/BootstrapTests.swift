import XCTest
@testable import MochiCore

final class BootstrapTests: XCTestCase {
    func testStatusIsReady() {
        XCTAssertEqual(Bootstrap.status(), "ready")
    }

    func testVersionIsNotEmpty() {
        XCTAssertFalse(Bootstrap.targetVersion.isEmpty)
    }

    func testSmokeAlwaysPasses() {
        XCTAssertTrue(true)
    }
}
