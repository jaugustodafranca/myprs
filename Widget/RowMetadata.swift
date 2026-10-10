import SwiftUI

struct MetadataItem: Identifiable {
    enum Kind { case draft, checks, diff, files, unanswered, review, conflicts }

    let kind: Kind
    let content: Text
    let color: Color

    var id: Kind { kind }

    init(kind: Kind, text: String, color: Color) {
        self.init(kind: kind, content: Text(text), color: color)
    }

    init(kind: Kind, content: Text, color: Color) {
        self.kind = kind
        self.content = content
        self.color = color
    }

    static func items(for pullRequest: PullRequest) -> [MetadataItem] {
        var items: [MetadataItem] = []
        if pullRequest.isDraft {
            items.append(MetadataItem(kind: .draft, text: "Draft", color: .secondary))
        }
        if pullRequest.checksTotal > 0 {
            let color: Color = pullRequest.checks == .failing ? .red : (pullRequest.checks == .passing ? .green : .secondary)
            items.append(MetadataItem(kind: .checks, text: "CI \(pullRequest.checksPassed)/\(pullRequest.checksTotal)", color: color))
        }
        let additions = Text("+\(CompactFormat.count(pullRequest.additions))").foregroundStyle(.green)
        let deletions = Text("\u{2212}\(CompactFormat.count(pullRequest.deletions))").foregroundStyle(.red)
        items.append(MetadataItem(kind: .diff, content: additions + Text(" ") + deletions, color: .secondary))
        let files = pullRequest.changedFiles
        items.append(MetadataItem(kind: .files, text: "\(files) file\(files == 1 ? "" : "s")", color: .secondary))
        if pullRequest.unansweredThreads > 0 {
            items.append(MetadataItem(kind: .unanswered, text: "\(pullRequest.unansweredThreads) to answer", color: .orange))
        }
        switch pullRequest.review {
        case .approved: items.append(MetadataItem(kind: .review, text: "Approved", color: .green))
        case .changesRequested: items.append(MetadataItem(kind: .review, text: "Changes requested", color: .red))
        case .waiting: break
        }
        if pullRequest.hasConflicts {
            items.append(MetadataItem(kind: .conflicts, text: "Conflicts", color: .red))
        }
        return items
    }

    func isDroppable(whenSpaceIsTight tightness: Int) -> Bool {
        switch kind {
        case .files: tightness >= 1
        case .diff: tightness >= 2
        case .draft: tightness >= 3
        default: false
        }
    }
}
