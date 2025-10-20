import SwiftModCore
import SwiftModRules
import TSCBasic

public extension Configuration {
    nonisolated(unsafe) static let template: Configuration = {
        let format = Format(
            indent: .spaces(4),
            lineBreakBeforeEachArgument: true
        )

        return Configuration(
            format: format,
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
        )
    }()
}
