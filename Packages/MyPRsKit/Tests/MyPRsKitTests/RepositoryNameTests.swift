import Testing
@testable import MyPRsKit

struct RepositoryNameTests {
    @Test func dropsTheOwner() {
        #expect(RepositoryName.short("GreenSpark-Software/greenspark-aws") == "greenspark-aws")
    }

    @Test func keepsANameWithoutOwner() {
        #expect(RepositoryName.short("greenspark-aws") == "greenspark-aws")
    }

    @Test func keepsAnEmptyRepositoryPart() {
        #expect(RepositoryName.short("owner/") == "owner/")
    }
}
