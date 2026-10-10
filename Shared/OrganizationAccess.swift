struct OrganizationAccess: Equatable {
    var restrictedOrganizations: [String] = []
    var needsReauth = false
}
