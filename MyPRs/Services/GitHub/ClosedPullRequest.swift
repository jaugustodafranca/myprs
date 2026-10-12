import Foundation

struct ClosedPullRequest: Hashable, Identifiable, Sendable {
    let id: String
    let number: Int
    let title: String
    let url: URL
    let repository: String
    let headBranch: String
    let baseBranch: String
    let state: ClosedState
    let endedAt: Date
    let additions: Int
    let deletions: Int
    let changedFiles: Int

    init(
        id: String,
        number: Int,
        title: String,
        url: URL,
        repository: String,
        headBranch: String,
        baseBranch: String,
        state: ClosedState,
        endedAt: Date,
        additions: Int,
        deletions: Int,
        changedFiles: Int
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.repository = repository
        self.headBranch = headBranch
        self.baseBranch = baseBranch
        self.state = state
        self.endedAt = endedAt
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
    }
}
