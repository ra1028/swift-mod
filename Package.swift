// swift-tools-version:5.6

import PackageDescription

let testsSuffix = "Tests"

let core = Target.target(
    name: "SwiftModCore",
    dependencies: [
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
        .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
        "Yams",
    ]
)

let coreTests = Target.testTarget(
    name: core.name + testsSuffix,
    dependencies: [.target(name: core.name)] + core.dependencies
)

let rules = Target.target(
    name: "SwiftModRules",
    dependencies: [.target(name: core.name)] + core.dependencies
)

let rulesTests = Target.testTarget(
    name: rules.name + testsSuffix,
    dependencies: [.target(name: rules.name)] + rules.dependencies
)

let commands = Target.target(
    name: "SwiftModCommands",
    dependencies: [.target(name: rules.name)] + rules.dependencies
)

let commandsTests = Target.testTarget(
    name: commands.name + testsSuffix,
    dependencies: [.target(name: commands.name)] + commands.dependencies
)

let cli = Target.executableTarget(
    name: "swift-mod",
    dependencies: [.target(name: commands.name)] + commands.dependencies
)

let package = Package(
    name: "swift-mod",
    products: [
        .executable(name: "swift-mod", targets: [cli.name])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .upToNextMinor(from: "0.50600.1")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.2.3"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        cli,
        commands,
        commandsTests,
        rules,
        rulesTests,
        core,
        coreTests,
    ],
    swiftLanguageVersions: [.v5]
)
