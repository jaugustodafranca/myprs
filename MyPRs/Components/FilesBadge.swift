import SwiftUI

struct FilesBadge: View {
    let count: Int

    init(count: Int) {
        self.count = count
    }

    var body: some View {
        Badge(text: "\(count) file\(count == 1 ? "" : "s")")
    }
}
