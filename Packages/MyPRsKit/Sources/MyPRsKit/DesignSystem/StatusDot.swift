import SwiftUI

public struct StatusDot: View {
    let pullRequest: PullRequest

    public init(pullRequest: PullRequest) {
        self.pullRequest = pullRequest
    }

    private var color: Color {
        if pullRequest.checks == .failing { return .red }
        if pullRequest.unansweredThreads > 0 { return .orange }
        if pullRequest.checks == .passing { return .green }
        return .gray
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}
