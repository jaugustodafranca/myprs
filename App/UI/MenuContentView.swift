import SwiftUI

struct MenuContentView: View {
    let monitor: PullRequestMonitor
    let updater: Updater

    var body: some View {
        Group {
            if monitor.isSignedIn {
                signedInContent
            } else {
                SignedOutView(monitor: monitor)
            }
        }
        .frame(width: 360)
    }

    private var signedInContent: some View {
        VStack(spacing: 0) {
            header
            Divider()
            pullRequestList
            if let error = monitor.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            Divider()
            SettingsSection(monitor: monitor, updater: updater)
            Divider()
            Button("Quit MyPRs") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("MyPRs").font(.headline)
                if let fetchedAt = monitor.snapshot?.fetchedAt {
                    Text("Updated \(fetchedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if monitor.isRefreshing {
                ProgressView().controlSize(.small)
            } else {
                Button { Task { await monitor.refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh now")
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var pullRequestList: some View {
        if monitor.pullRequests.isEmpty {
            Text(monitor.snapshot == nil ? "Loading…" : "No open pull requests")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(monitor.pullRequests) { PullRequestRow(pullRequest: $0) }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 420)
        }
    }
}
