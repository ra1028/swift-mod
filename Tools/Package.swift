// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Tools",
    dependencies: [
        .package(url: "https://github.com/apple/swift-format.git", .upToNextMinor(from: "510.1.0")),
    ]
)
