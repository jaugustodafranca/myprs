import Foundation

struct PullRequestChange: Equatable {
    enum Kind: Equatable {
        case checksFailed
        case newUnansweredThreads
    }

    let kind: Kind
    let pullRequest: PullRequest
}

enum ChangeDetector {
    static func changes(from previous: [PullRequest], to current: [PullRequest]) -> [PullRequestChange] {
        let previousByID = Dictionary(uniqueKeysWithValues: previous.map { ($0.id, $0) })

        return current.flatMap { pullRequest -> [PullRequestChange] in
            guard let before = previousByID[pullRequest.id] else { return [] }
            var changes: [PullRequestChange] = []
            if before.checks != .failing, pullRequest.checks == .failing {
                changes.append(PullRequestChange(kind: .checksFailed, pullRequest: pullRequest))
            }
            if pullRequest.unansweredThreads > before.unansweredThreads {
                changes.append(PullRequestChange(kind: .newUnansweredThreads, pullRequest: pullRequest))
            }
            return changes
        }
    }
}
