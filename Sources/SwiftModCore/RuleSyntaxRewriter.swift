import Foundation
import SwiftSyntax

private extension NSRegularExpression {
    static let ignoreRules = try! NSRegularExpression(pattern: #"^.*swift-mod-ignore(:\s+(([A-z0-9]+[,\s]*)+))?.*$"#)
}

public protocol RuleSyntaxRewriterProtocol: SyntaxRewriter {
    associatedtype Options: Codable

    init(name: String, options: Options, format: Format)
}

open open class RuleSyntaxRewriter<Options: Codable>: SyntaxRewriter, RuleSyntaxRewriterProtocol {
    public let name: String
    public let options: Options
    public let format: Format

    public required init(name: String, options: Options, format: Format) {
        self.name = name
        self.options = options
        self.format = format
    }

    public final override func visitAny(_ node: Syntax) -> Syntax? {
        // Whether to extract ignore options from comments
        let shouldExtractNode = node.is(MemberBlockItemSyntax.self) || node.is(CodeBlockItemSyntax.self)

        guard shouldExtractNode, let leadingTrivia = node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia else {
            return nil
        }

        for piece in leadingTrivia {
            let comment: String

            // Supports line comments (// swift-mod-ignore) or block comments (/* swift-mod-ignore */)
            switch piece {
            case .lineComment(let text), .blockComment(let text):
                comment = text

            default:
                continue
            }

            let range = NSRange(comment.startIndex..<comment.endIndex, in: comment)

            guard let match = NSRegularExpression.ignoreRules.firstMatch(in: comment, options: [], range: range) else {
                continue
            }

            // Text raange for list of identifiers like "foo, bar, baz"
            let matchRange = match.range(at: 2)

            guard matchRange.location != NSNotFound, let identifiersRange = Range(matchRange, in: comment) else {
                // Identifier is not specified, so ignore all rules.
                return node
            }

            let shouldIgnore = comment[identifiersRange]
                .components(separatedBy: ",")
                .lazy
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .contains(name)

            if shouldIgnore {
                return node
            }
        }

        return nil
    }
}
