import SwiftSyntax

public extension TokenKind {
    static let openKeywardText = "open"
    static let openKeyward = TokenKind.identifier(openKeywardText)
    static let finalKeyward = TokenKind.identifier("final")

    var isOptional: Bool {
        self == .identifier("Optional")
    }
}
