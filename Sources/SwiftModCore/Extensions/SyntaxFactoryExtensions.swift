import SwiftSyntax

public extension SyntaxFactory {
    static func makeOpenKeyward() -> TokenSyntax {
        makeIdentifier(TokenKind.openKeywardText)
    }

    static func makeDeclModifier(name: TokenSyntax) -> DeclModifierSyntax {
        makeDeclModifier(name: name, detailLeftParen: nil, detail: nil, detailRightParen: nil)
    }

    static func makeNilExpr() -> ExprSyntax {
        makeNilLiteralExpr(nilKeyword: SyntaxFactory.makeNilKeyword())
    }

    static func replacingTrivia<S: Syntax>(
        _ node: S,
        for token: TokenSyntax,
        leading: Trivia? = nil,
        trailing: Trivia? = nil
    ) -> S {
        TriviaReplacer(for: token, leading: leading, trailing: trailing).visit(node) as! S
    }

    static func movingLeadingTrivia<L: Syntax, T: Syntax>(
        leading: L,
        for leadingToken: TokenSyntax,
        trailing: T,
        for trailingToken: TokenSyntax
    ) -> (leading: L, trailing: T) {
        let leading = TriviaReplacer(for: leadingToken, leading: trailingToken.leadingTrivia).visit(leading) as! L
        let trailing = TriviaReplacer(for: trailingToken, leading: []).visit(trailing) as! T
        return (leading, trailing)
    }
}

private final class TriviaReplacer: SyntaxRewriter {
    let token: TokenSyntax
    let leading: Trivia
    let trailing: Trivia

    init(for token: TokenSyntax, leading: Trivia? = nil, trailing: Trivia? = nil) {
        self.token = token
        self.leading = leading ?? token.leadingTrivia
        self.trailing = trailing ?? token.trailingTrivia
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        guard token == self.token else { return token }

        return
            token
            .withLeadingTrivia(leading)
            .withTrailingTrivia(trailing)
    }
}
