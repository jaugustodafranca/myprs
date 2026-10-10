import SwiftUI

@main
struct MyPRsApp: App {
    @State private var updater = Updater()

    var body: some Scene {
        MenuBarExtra("MyPRs", systemImage: "arrow.triangle.pull") {
            Text("Hello")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
