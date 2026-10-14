import Testing
@testable import MyPRsKit

struct RepositoryNameTests {
    @Test func dropsTheOwner() {
        #expect(RepositoryName.short("acme/storefront") == "storefront")
    }

    @Test func keepsANameWithoutOwner() {
        #expect(RepositoryName.short("storefront") == "storefront")
    }

    @Test func keepsAnEmptyRepositoryPart() {
        #expect(RepositoryName.short("owner/") == "owner/")
    }
}
