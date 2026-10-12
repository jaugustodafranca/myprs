
enum RowDetail {
    case compact, regular, full

    var showsBranch: Bool { self != .compact }
    var showsBadges: Bool { self == .full }
    var showsCopyBranch: Bool { self == .full }
}
