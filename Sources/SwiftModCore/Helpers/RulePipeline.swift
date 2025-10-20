import SwiftSyntax

public struct RulePipeline: @unchecked Sendable {
    private let rules: ContiguousArray<Rule>

    public init<S: Sequence>(_ rules: S) where S.Element == Rule {
        self.rules = ContiguousArray(rules)
    }

    public func visit(_ node: Syntax) -> Syntax {
        rules.reduce(node) { node, rule in
            rule.rewriter().rewrite(node)
        }
    }
}
