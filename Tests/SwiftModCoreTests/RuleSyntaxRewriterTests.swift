import SwiftModCore
import SwiftSyntax
import XCTest

final class RuleSyntaxRewriterTests: XCTestCase {
    let testRule = RuleSyntaxRewriter<Int>(name: "test", options: 0, format: .default)

    func testIgnoreCommentForMemberDeclListItem() {
        let node = MemberBlockItemSyntax(
            decl: DeclSyntax(
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: [],
                    bindingSpecifier: TokenSyntax.keyword(.let),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: PatternSyntax(
                                IdentifierPatternSyntax(
                                    identifier: TokenSyntax.identifier("test")
                                )
                            ),
                            typeAnnotation: nil,
                            initializer: InitializerClauseSyntax(
                                equal: TokenSyntax.equalToken(),
                                value: ExprSyntax(IntegerLiteralExprSyntax(digits: .integerLiteral("100")))
                            ),
                            accessorBlock: nil,
                            trailingComma: nil
                        )
                    ])
                )
            ),
            semicolon: nil
        )

        let notIgnoreNode = testRule.visitAny(Syntax(node))
        let ignoreTestNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore: test"))))
        let ignoreOtherNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore: other"))))
        let ignoreAllNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore"))))

        XCTAssertNil(notIgnoreNode)
        XCTAssertNotNil(ignoreTestNode)
        XCTAssertNil(ignoreOtherNode)
        XCTAssertNotNil(ignoreAllNode)
    }

    func testIgnoreCommentForCodeBlockItem() {
        let node = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("test")))),
            semicolon: nil
        )

        let notIgnoreNode = testRule.visitAny(Syntax(node))
        let ignoreTestNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore: test"))))
        let ignoreOtherNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore: other"))))
        let ignoreAllNode = testRule.visitAny(Syntax(node.with(\.leadingTrivia, .lineComment("swift-mod-ignore"))))

        XCTAssertNil(notIgnoreNode)
        XCTAssertNotNil(ignoreTestNode)
        XCTAssertNil(ignoreOtherNode)
        XCTAssertNotNil(ignoreAllNode)
    }
}
