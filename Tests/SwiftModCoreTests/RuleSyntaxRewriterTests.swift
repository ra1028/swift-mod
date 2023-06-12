import SwiftModCore
import SwiftSyntax
import XCTest

final class RuleSyntaxRewriterTests: XCTestCase {
    let testRule = RuleSyntaxRewriter<Int>(name: "test", options: 0, format: .default)

    func testIgnoreCommentForMemberDeclListItem() {
        let node = MemberDeclListItemSyntax(
            decl: DeclSyntax(
                VariableDeclSyntax(
                    attributes: nil,
                    modifiers: nil,
                    bindingKeyword: .keyword(.let),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: PatternSyntax(
                                IdentifierPatternSyntax(
                                    identifier: .identifier("test")
                                )
                            ),
                            typeAnnotation: nil,
                            initializer: InitializerClauseSyntax(
                                equal: .equalToken(),
                                value: IntegerLiteralExprSyntax(digits: .integerLiteral("100"))
                            ),
                            accessor: nil,
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
            item: .expr(ExprSyntax(IdentifierExprSyntax(identifier: .identifier("test")))),
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
