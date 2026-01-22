import Foundation

public protocol OnboardingPersisting {
    func hasSeenOnboarding() -> Bool
    func setSeen()
}

public final class UserDefaultsOnboardingStore: OnboardingPersisting {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "mochi.onboarding.seen") {
        self.defaults = defaults
        self.key = key
    }

    public func hasSeenOnboarding() -> Bool {
        defaults.bool(forKey: key)
    }

    public func setSeen() {
        defaults.set(true, forKey: key)
    }
}
