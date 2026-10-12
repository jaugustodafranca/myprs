@testable import MyPRs
import MyPRsKit
import Testing
import Foundation

struct RefreshIntervalTests {
    @Test(arguments: [300.0, 600, 900, 1800, 3600])
    func keepsStoredValueThatIsAnOption(stored: Double) {
        #expect(RefreshInterval.restored(from: stored) == stored)
    }

    @Test(arguments: [0.0, 60, 120, 1234])
    func resetsOldOrUnknownValuesToStandard(stored: Double) {
        #expect(RefreshInterval.restored(from: stored) == 1800)
    }
}
