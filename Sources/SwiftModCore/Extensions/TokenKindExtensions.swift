import SwiftSyntax

public extension TokenKind {
    var isOptional: Bool {
        self == .identifier("Optional")
    }
}
