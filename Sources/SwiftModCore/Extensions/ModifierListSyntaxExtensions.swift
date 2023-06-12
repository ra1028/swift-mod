import SwiftSyntax

public extension ModifierListSyntax {
    var hasFinal: Bool {
        contains { $0.name.tokenKind == .keyword(.final) }
    }

    var hasStatic: Bool {
        contains {
            $0.name.tokenKind == .keyword(.static)
        }
    }

    var accessLevelModifier: DeclModifierSyntax? {
        first { modifier in
            switch modifier.name.tokenKind {
            case .keyword(.open),
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
