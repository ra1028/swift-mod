import SwiftModCore
import SwiftSyntax
import XCTest

final class RuleSyntaxRewriterTests: XCTestCase {
    let testRule = RuleSyntaxRewriter<Int>(identifier: "test", options: 0, format: .default)

    func testIgnoreCommentForMemberDeclListItem() {
        let node = SyntaxFactory.makeMemberDeclListItem(
            decl: SyntaxFactory.makeVariableDecl(
                attributes: nil,
                modifiers: nil,
                letOrVarKeyword: SyntaxFactory.makeLetKeyword(),
                bindings: SyntaxFactory.makePatternBindingList([
                    SyntaxFactory.makePatternBinding(
                        pattern: SyntaxFactory.makeIdentifierPattern(
                            identifier: SyntaxFactory.makeIdentifier("test")
                        ),
                        typeAnnotation: nil,
                        initializer: SyntaxFactory.makeInitializerClause(
                            equal: SyntaxFactory.makeEqualToken(),
                            value: SyntaxFactory.makeVariableExpr("100")
                        ),
                        accessor: nil,
                        trailingComma: nil
                    ),
                ])
            ),
            semicolon: nil
        )

        let notIgnoreNode = testRule.visitAny(node)
        let ignoreTestNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore: test")))
        let ignoreOtherNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore: other")))
        let ignoreAllNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore")))

        XCTAssertNil(notIgnoreNode)
        XCTAssertNotNil(ignoreTestNode)
        XCTAssertNil(ignoreOtherNode)
        XCTAssertNotNil(ignoreAllNode)
    }

    func testIgnoreCommentForCodeBlockItem() {
        let node = SyntaxFactory.makeCodeBlockItem(
            item: SyntaxFactory.makeIdentifier("test"),
            semicolon: nil,
            errorTokens: nil
        )

        let notIgnoreNode = testRule.visitAny(node)
        let ignoreTestNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore: test")))
        let ignoreOtherNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore: other")))
        let ignoreAllNode = testRule.visitAny(node.withLeadingTrivia(.lineComment("swift-mod-ignore")))

        XCTAssertNil(notIgnoreNode)
        XCTAssertNotNil(ignoreTestNode)
        XCTAssertNil(ignoreOtherNode)
        XCTAssertNotNil(ignoreAllNode)
    }
}
