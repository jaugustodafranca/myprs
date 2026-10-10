import Foundation
import Testing

struct OrganizationAccessTests {
    private func restricted(_ json: String) throws -> [String] {
        let response = try JSONDecoder().decode(OrganizationAccessResponse.self, from: Data(json.utf8))
        return RestrictedOrganizations.from(response)
    }

    private let nodes = #"{"viewer":{"organizations":{"nodes":[{"login":"open-org","repositories":{"totalCount":3}},{"login":"locked-org","repositories":null}]}}}"#

    @Test func noErrorsMeansNothingRestricted() throws {
        #expect(try restricted(#"{"data":\#(nodes)}"#).isEmpty)
    }

    @Test func mapsRestrictedOrganizationByPathIndex() throws {
        let error = #"{"type":"FORBIDDEN","message":"`locked-org` forbids access via OAuth App access restrictions.","path":["viewer","organizations","nodes",1,"repositories"]}"#
        #expect(try restricted(#"{"data":\#(nodes),"errors":[\#(error)]}"#) == ["locked-org"])
    }

    @Test func ignoresUnrelatedErrors() throws {
        let other = #"{"type":"FORBIDDEN","message":"Resource not accessible","path":["viewer","organizations","nodes",1,"repositories"]}"#
        let wrongPath = #"{"type":"FORBIDDEN","message":"OAuth App access restrictions","path":["viewer","login"]}"#
        let rateLimit = #"{"type":"RATE_LIMITED","message":"OAuth App access restrictions","path":["viewer","organizations","nodes",0,"repositories"]}"#
        #expect(try restricted(#"{"data":\#(nodes),"errors":[\#(other),\#(wrongPath),\#(rateLimit)]}"#).isEmpty)
    }

    @Test func missingDataMeansNothingRestricted() throws {
        let error = #"{"type":"FORBIDDEN","message":"OAuth App access restrictions","path":["viewer","organizations","nodes",0,"repositories"]}"#
        #expect(try restricted(#"{"data":null,"errors":[\#(error)]}"#).isEmpty)
        #expect(try restricted(#"{"data":{"viewer":null}}"#).isEmpty)
    }

    @Test func ignoresIndicesOutsideTheList() throws {
        let error = #"{"type":"FORBIDDEN","message":"OAuth App access restrictions","path":["viewer","organizations","nodes",9,"repositories"]}"#
        #expect(try restricted(#"{"data":\#(nodes),"errors":[\#(error)]}"#).isEmpty)
    }
}

struct OrganizationAccessAttentionTests {
    @Test func needsAttentionOnlyWhenRestrictedOrReauth() {
        #expect(!OrganizationAccess().needsAttention)
        #expect(OrganizationAccess(restrictedOrganizations: ["locked"]).needsAttention)
        #expect(OrganizationAccess(needsReauth: true).needsAttention)
    }
}
