// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyPRsKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MyPRsKit", targets: ["MyPRsKit"]),
    ],
    targets: [
        .target(name: "MyPRsKit"),
        .testTarget(name: "MyPRsKitTests", dependencies: ["MyPRsKit"]),
    ]
)
