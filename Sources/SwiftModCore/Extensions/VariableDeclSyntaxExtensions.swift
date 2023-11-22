import SwiftSyntax

public extension VariableDeclSyntax {
    var identifier: IdentifierPatternSyntax? {
        bindings.lazy
            .compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }
            .first
    }

    var typeAnnotation: TypeAnnotationSyntax? {
        bindings.lazy
            .compactMap { $0.typeAnnotation }
            .first
    }

    var value: ExprSyntax? {
        bindings.lazy
            .compactMap { $0.initializer?.value }
            .first
    }

    var hasAccessor: Bool {
        bindings.contains { $0.accessorBlock != nil }
    }
}
