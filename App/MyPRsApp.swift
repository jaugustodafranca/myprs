import SwiftUI

@main
struct MyPRsApp: App {
    var body: some Scene {
        MenuBarExtra("MyPRs", systemImage: "arrow.triangle.pull") {
            Text("Hello")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
