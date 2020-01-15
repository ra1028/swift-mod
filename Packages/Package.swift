// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Packages",
    dependencies: [
        .package(url: "https://github.com/ra1028/swift-format.git", .branch("swift-5.1-branch-latest")),
    ]
)
