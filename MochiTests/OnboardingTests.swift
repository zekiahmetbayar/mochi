import XCTest
@testable import MochiCore

final class OnboardingTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: "mochi.onboarding.test")
        super.tearDown()
    }

    func testStorePersistsSeenFlag() {
        let defaults = UserDefaults(suiteName: "mochi.onboarding.test")!
        defaults.removePersistentDomain(forName: "mochi.onboarding.test")
        let store = UserDefaultsOnboardingStore(defaults: defaults)
        XCTAssertFalse(store.hasSeenOnboarding())
        store.setSeen()
        XCTAssertTrue(store.hasSeenOnboarding())
    }
}
