import Foundation
import MyPRsKit

struct CheckSummary {
    let status: CheckStatus
    let passed: Int
    let total: Int
    let failures: [String]

    private struct WorkflowKey: Hashable {
        let workflow: String
        let event: String
    }

    private enum ResultKey: Hashable {
        case job(name: String, event: String?)
        case status(String)
    }

    init(_ contexts: [GitHubResponse.CheckContext]) {
        let workflows = Dictionary(grouping: contexts.compactMap(\.checkSuite?.workflowRun)) { run in
            WorkflowKey(workflow: run.workflow.name, event: run.event)
        }
        let newestRuns = workflows.compactMapValues(Self.newestRunID)

        var attempts: [ResultKey: [GitHubResponse.CheckContext]] = [:]
        for context in contexts {
            let key: ResultKey
            if let name = context.name {
                let run = context.checkSuite?.workflowRun
                if let run {
                    let workflow = WorkflowKey(workflow: run.workflow.name, event: run.event)
                    guard newestRuns[workflow] == run.id else { continue }
                }
                key = .job(name: name, event: run?.event)
            } else if let name = context.context {
                key = .status(name)
            } else {
                continue
            }
            attempts[key, default: []].append(context)
        }

        let latest = attempts.values.compactMap(Self.newestResult)
        total = latest.count
        passed = latest.filter { $0.result == .passing }.count
        failures = latest.filter { $0.result == .failing }.map(\.failureLabel).sorted()
        if !failures.isEmpty { status = .failing }
        else if passed < total { status = .running }
        else { status = total == 0 ? .none : .passing }
    }

    private static func newestRunID(_ runs: [GitHubResponse.WorkflowRun]) -> String? {
        let newestDate = runs.map(\.createdAt).max()
        let tied = runs.filter { $0.createdAt == newestDate }
        if tied.allSatisfy({ $0.databaseId != nil }) {
            return tied.max { ($0.databaseId ?? 0) < ($1.databaseId ?? 0) }?.id
        }
        return tied.max { ($0.runNumber, $0.id) < ($1.runNumber, $1.id) }?.id
    }

    private static func newestResult(_ attempts: [GitHubResponse.CheckContext]) -> GitHubResponse.CheckContext? {
        let dated = attempts.filter { $0.resultDate != nil }.max { $0.resultTime < $1.resultTime }
        var candidates = attempts.filter { $0.resultDate == nil }
        guard !candidates.isEmpty else { return dated }

        // GitHub can return a queued retry before assigning it a start time.
        if let dated { candidates.append(dated) }
        if candidates.allSatisfy({ $0.databaseId != nil }) {
            return candidates.max { ($0.databaseId ?? 0) < ($1.databaseId ?? 0) }
        }
        return candidates.max { $0.suiteOrder < $1.suiteOrder }
    }
}

private extension GitHubResponse.CheckContext {
    var resultDate: Date? { startedAt ?? createdAt ?? completedAt }

    var resultTime: (Date, Date, Int64) {
        (resultDate ?? .distantPast, completedAt ?? .distantPast, databaseId ?? 0)
    }

    var suiteOrder: (Date, Int, Int64) {
        // Within one suite, an unorderable pending attempt keeps the badge running.
        (checkSuite?.createdAt ?? .distantPast, resultDate == nil && result == .running ? 1 : 0, databaseId ?? 0)
    }

    var result: CheckStatus {
        switch conclusion ?? state ?? status {
        case "SUCCESS", "NEUTRAL", "SKIPPED": .passing
        case "FAILURE", "ERROR", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE", "STALE", "CANCELLED": .failing
        default: .running
        }
    }

    var failureLabel: String {
        if let name { return name }
        return [context, description].compactMap { $0 }.joined(separator: " — ")
    }
}
