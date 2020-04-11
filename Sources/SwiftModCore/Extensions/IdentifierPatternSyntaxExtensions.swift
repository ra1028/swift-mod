import SwiftSyntax

public extension IdentifierPatternSyntax {
    func withoutBackticks() -> IdentifierPatternSyntax {
        IdentifierBackticksRemover()
            .visit(self)
            .as(Self.self)!
    }
}

private final class IdentifierBackticksRemover: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> Syntax {
        guard case .identifier(let text) = token.tokenKind else {
            return Syntax(token)
        }

        return Syntax(token.withKind(.identifier(text.replacingOccurrences(of: "`", with: ""))))
    }
}
