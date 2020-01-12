import SwiftModCore
import SwiftModRules
import TSCBasic

public extension Configuration {
    static let template: Configuration = {
        let format = Format(
            indent: .spaces(4),
            lineBreakBeforeEachArgument: true
        )

        return Configuration(
            format: format,
            targets: [
                "main": Target(
                    paths: [
                        RelativePath("."),
                    ],
                    excludedPaths: [
                        RelativePath(".build"),
                        RelativePath("Package.swift"),
                        RelativePath("**/main.swift"),
                        RelativePath("**/LinuxMain.swift"),
                        RelativePath("**/XCTestManifests.swift"),
                    ],
                    rules: [
                        DefaultAccessLevelRule(
                            options: DefaultAccessLevelRule.Options(
                                accessLevel: .openOrPublic,
                                implicitInternal: true
                            ),
                            format: format
                        ),
                        DefaultMemberwiseInitializerRule(
                            options: DefaultMemberwiseInitializerRule.Options(
                                implicitInitializer: false,
                                implicitInternal: true,
                                ignoreClassesWithInheritance: false
                            ),
                            format: format
                        ),
                    ]
                ),
            ]
        )
    }()
}
