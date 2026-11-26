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
        var newestRuns: [WorkflowKey: GitHubResponse.WorkflowRun] = [:]
        for context in contexts {
            guard let run = context.checkSuite?.workflowRun else { continue }
            let key = WorkflowKey(workflow: run.workflow.name, event: run.event)
            if let newest = newestRuns[key], (newest.createdAt, newest.databaseId) >= (run.createdAt, run.databaseId) {
                continue
            }
            newestRuns[key] = run
        }

        var latest: [ResultKey: GitHubResponse.CheckContext] = [:]
        for context in contexts {
            let key: ResultKey
            if let name = context.name {
                let run = context.checkSuite?.workflowRun
                if let run {
                    let workflow = WorkflowKey(workflow: run.workflow.name, event: run.event)
                    guard newestRuns[workflow]?.databaseId == run.databaseId else { continue }
                }
                key = .job(name: name, event: run?.event)
            } else if let name = context.context {
                key = .status(name)
            } else {
                continue
            }
            if let previous = latest[key], previous.resultTime > context.resultTime { continue }
            latest[key] = context
        }

        total = latest.count
        passed = latest.values.filter { $0.result == .passing }.count
        failures = latest.values.filter { $0.result == .failing }.map(\.failureLabel).sorted()
        if !failures.isEmpty { status = .failing }
        else if passed < total { status = .running }
        else { status = total == 0 ? .none : .passing }
    }
}

private extension GitHubResponse.CheckContext {
    var resultTime: (Date, Date) {
        (startedAt ?? createdAt ?? .distantPast, completedAt ?? .distantPast)
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
