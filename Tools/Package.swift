// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Tools",
    dependencies: [
        .package(url: "https://github.com/apple/swift-format.git", .branch("swift-5.5-branch")),
    ],
    targets: [.target(name: "Tools", path: "TargetStub")]
)
