import SwiftSyntax

public extension DeclModifierListSyntax {
    var hasFinal: Bool {
        contains { $0.name.tokenKind == .finalKeyward }
    }

    var hasStatic: Bool {
        contains { $0.name.tokenKind == .keyword(.static) }
    }

    var accessLevelModifier: DeclModifierSyntax? {
        first { modifier in
            switch modifier.name.tokenKind {
            case .openKeyward,
                .keyword(.public),
                .keyword(.internal),
                .keyword(.fileprivate),
                .keyword(.private):
                return true

            default:
                return false
            }
        }
    }
}
