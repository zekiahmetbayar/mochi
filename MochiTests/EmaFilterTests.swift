import XCTest
@testable import MochiCore

final class EmaFilterTests: XCTestCase {
    func testEmaConvergesBetweenSamples() {
        var filter = EmaFilter(alpha: 0.5)
        let s1 = filter.update(sample: 0)
        XCTAssertEqual(s1, 0)
        let s2 = filter.update(sample: 100)
        XCTAssertEqual(s2, 50)
        let s3 = filter.update(sample: 100)
        XCTAssertEqual(s3, 75)
        let s4 = filter.update(sample: 100)
        XCTAssertEqual(s4, 87.5)
    }
}
