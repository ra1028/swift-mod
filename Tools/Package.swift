// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "Tools",
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format.git", exact: "601.0.0"),
    ]
)
