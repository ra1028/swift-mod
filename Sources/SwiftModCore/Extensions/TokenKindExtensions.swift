import SwiftSyntax

public extension TokenKind {
    static let openKeywardText = "open"
    static let openKeyward = TokenKind.identifier(openKeywardText)

    var isOptional: Bool {
        self == .identifier("Optional")
    }
}
