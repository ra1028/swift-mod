import SwiftSyntax

public extension IdentifierPatternSyntax {
    func withoutBackticks() -> IdentifierPatternSyntax {
        IdentifierBackticksRemover()
            .visit(self)
            .as(Self.self)!
    }
}

private final class IdentifierBackticksRemover: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard case .identifier(let text) = token.tokenKind else {
            return token
        }

        return token.with(\.tokenKind, .identifier(text.replacingOccurrences(of: "`", with: "")))
    }
}
