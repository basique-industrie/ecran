import Foundation

public enum EcranSelfTests {
    @MainActor
    public static func run() async -> Int {
        let test = TestHarness()
        runIdentityAndSettingsTests(test)
        runTitleExtractionTests(test)
        runWindowClassificationTests(test)
        runWindowLayoutTests(test)
        runSnapAndURLTests(test)
        runVerifiedBugfixTests(test)
        runIntegrationAndParityTests(test)
        runStatusMenuTests(test)
        runSecurityHardeningTests(test)
        return test.finish()
    }
}
