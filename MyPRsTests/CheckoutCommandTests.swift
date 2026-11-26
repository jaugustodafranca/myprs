import Testing
@testable import MyPRs

struct CheckoutCommandTests {
    @Test func offersCommandsOnlyForLiteralNonOptionArguments() {
        #expect(CheckoutCommand.forBranch("feature/review_1.2-fix") == "git checkout feature/review_1.2-fix")
        for name in ["", "--help", "two words", "team's-branch", "fix$1", "fix\n"] {
            #expect(CheckoutCommand.forBranch(name) == nil)
        }
    }
}
