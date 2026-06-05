// swift-tools-version:6.3

import PackageDescription

let package = Package(
    name: "Tools",
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format.git", exact: "602.0.0"),
    ]
)
