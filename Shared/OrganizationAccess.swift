struct OrganizationAccess: Equatable {
    var restrictedOrganizations: [String] = []
    var needsReauth = false

    var needsAttention: Bool { needsReauth || !restrictedOrganizations.isEmpty }
}
