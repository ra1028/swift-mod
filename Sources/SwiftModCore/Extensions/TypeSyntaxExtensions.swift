import SwiftSyntax

public extension TypeSyntax {
    var isOptional: Bool {
        if let identifier = self.as(IdentifierTypeSyntax.self), identifier.name.tokenKind.isOptional {
            return true
        }
        else {
            return self.is(OptionalTypeSyntax.self)
        }
    }
}
