import AppKit

/// Runs `work` in an app without a Dock icon, menu bar or focus, then exits with 0, or 1 if `work` threw.
@MainActor
func runOffscreen(_ work: @escaping @MainActor () async throws -> Void) {
    Task { @MainActor in
        do {
            try await work()
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("Preview failed: \(error)\n".utf8))
            exit(1)
        }
    }
    NSApplication.shared.setActivationPolicy(.prohibited)
    NSApplication.shared.run()
}
