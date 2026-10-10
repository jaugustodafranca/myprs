import SwiftUI

struct SignedOutView: View {
    let monitor: PullRequestMonitor

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.pull")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Your open pull requests, one click away.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Sign in to see CI status, reviews and unanswered comments for every PR you authored.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if monitor.isSigningIn {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for GitHub in your browser…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Cancel") { monitor.cancelSignIn() }
            } else {
                Button("Sign in with GitHub") {
                    Task { await monitor.signIn() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            if let error = monitor.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            Divider()
            Button("Quit MyPRs") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
}
