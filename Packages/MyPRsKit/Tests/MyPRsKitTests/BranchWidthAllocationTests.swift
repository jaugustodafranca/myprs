import Testing
@testable import MyPRsKit

struct BranchWidthAllocationTests {
    @Test func keepsNaturalWidthsWhenBothFit() {
        let split = BranchWidthAllocation(headIdeal: 100, baseIdeal: 50, available: 200)
        #expect(split.head == 100)
        #expect(split.base == 50)
    }

    @Test func shortBaseLeavesTheRestToALongHead() {
        let split = BranchWidthAllocation(headIdeal: 400, baseIdeal: 40, available: 200)
        #expect(split.head == 160)
        #expect(split.base == 40)
    }

    @Test func longBaseCannotSqueezeTheHeadBelowItsMinimumShare() {
        let split = BranchWidthAllocation(headIdeal: 400, baseIdeal: 400, available: 200)
        #expect(abs(split.head - 110) < 0.001)
        #expect(abs(split.base - 90) < 0.001)
    }

    @Test func shortHeadKeepsItsNaturalWidthAgainstALongBase() {
        let split = BranchWidthAllocation(headIdeal: 30, baseIdeal: 400, available: 200)
        #expect(split.head == 30)
        #expect(split.base == 170)
    }

    @Test func neverExceedsTheAvailableWidth() {
        let split = BranchWidthAllocation(headIdeal: 400, baseIdeal: 400, available: -5)
        #expect(split.head == 0)
        #expect(split.base == 0)
    }
}
