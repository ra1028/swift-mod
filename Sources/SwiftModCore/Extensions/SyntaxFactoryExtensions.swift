// Should be renamed to TokenSyntax
import SwiftSyntax

public extension TokenSyntax {
    static func replacingTrivia<S: SyntaxProtocol>(
        _ node: S,
        for token: TokenSyntax,
        leading: Trivia? = nil,
        trailing: Trivia? = nil
    ) -> S {
        TriviaReplacer(for: token, leading: leading, trailing: trailing)
            .rewrite(Syntax(node))
            .as(S.self)!
    }

    static func movingLeadingTrivia<L: SyntaxProtocol, T: SyntaxProtocol>(
        leading: L,
        for leadingToken: TokenSyntax,
        trailing: T,
        for trailingToken: TokenSyntax
    ) -> (leading: L, trailing: T) {
        let leading = replacingTrivia(leading, for: leadingToken, leading: trailingToken.leadingTrivia)
        let trailing = replacingTrivia(trailing, for: trailingToken, leading: [])
        return (leading, trailing)
    }
}

private final class TriviaReplacer: SyntaxRewriter {
    let token: TokenSyntax
    let leading: Trivia
    let trailing: Trivia

    init(for token: TokenSyntax, leading: Trivia?, trailing: Trivia?) {
        self.token = token
        self.leading = leading ?? token.leadingTrivia
        self.trailing = trailing ?? token.trailingTrivia
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token == self.token else { return token }

        return token
            .with(\.leadingTrivia, leading)
            .with(\.trailingTrivia, trailing)
    }
}
