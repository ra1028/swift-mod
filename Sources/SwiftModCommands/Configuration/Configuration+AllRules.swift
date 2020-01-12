import SwiftModCore
import SwiftModRules

public extension Configuration {
    static let allRules: [AnyRule.Type] = [
        DefaultAccessLevelRule.self,
        DefaultMemberwiseInitializerRule.self,
    ]
}
