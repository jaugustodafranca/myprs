public enum RepositoryName {
    /// "Owner/repo" becomes "repo". A name without a slash is returned unchanged.
    public static func short(_ fullName: String) -> String {
        guard let slash = fullName.lastIndex(of: "/") else { return fullName }
        let name = fullName[fullName.index(after: slash)...]
        return name.isEmpty ? fullName : String(name)
    }
}
