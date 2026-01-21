import XCTest
#if os(macOS)
import AppKit
#endif

final class SpriteAssetLoadTests: XCTestCase {
    func testFixtureSpriteLoads() throws {
        #if os(macOS)
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "mochi_idle_0", withExtension: "png") else {
            XCTFail("Fixture sprite missing in test bundle")
            return
        }
        let image = NSImage(contentsOf: url)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
        XCTAssertGreaterThan(image?.size.height ?? 0, 0)
        #else
        throw XCTSkip("AppKit not available on this platform")
        #endif
    }
}
