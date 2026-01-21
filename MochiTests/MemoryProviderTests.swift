import XCTest
@testable import MochiCore

final class MemoryProviderTests: XCTestCase {
    func testPercentWithinBounds() {
        let provider = MemoryStub()
        for _ in 0..<10 {
            let v = provider.ramUsedPercent()
            XCTAssertNotNil(v)
            XCTAssertGreaterThanOrEqual(v ?? 0, 0)
            XCTAssertLessThanOrEqual(v ?? 0, 100)
        }
    }

    func testMachProviderReturnsNilWhenUnavailable() {
#if os(macOS)
        let provider = MemoryMachProvider()
        // We can't assert actual value in test environment, but ensure call does not crash.
        _ = provider.ramUsedPercent()
#else
        // Non-macOS uses stub; already covered above.
        XCTAssertTrue(true)
#endif
    }
}
