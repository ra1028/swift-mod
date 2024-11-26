// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "swift-mod",
    platforms: [
       .macOS("10.15")
    ],
    products: [
        .executable(
            name: "swift-mod",
            targets: ["swift-mod"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "510.0.3"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core.git", exact: "0.7.1"),
        .package(url: "https://github.com/jpsim/Yams.git", exact: "5.1.3")
    ],
    targets: [
        .executableTarget(
            name: "swift-mod",
            dependencies: ["SwiftModCommands"]
        ),
        .target(
            name: "SwiftModCommands",
            dependencies: [
                "SwiftModRules",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftModCommandsTests",
            dependencies: ["SwiftModCommands"]
        ),
        .target(
            name: "SwiftModRules",
            dependencies: ["SwiftModCore"]
        ),
        .testTarget(
            name: "SwiftModRulesTests",
            dependencies: ["SwiftModRules"]
        ),
        .target(
            name: "SwiftModCore",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "Yams",
            ]
        ),
        .testTarget(
            name: "SwiftModCoreTests",
            dependencies: ["SwiftModCore"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
