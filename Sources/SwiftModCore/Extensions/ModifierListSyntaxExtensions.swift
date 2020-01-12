import SwiftSyntax

public extension ModifierListSyntax {
    var hasFinal: Bool {
        contains { $0.name.tokenKind == .finalKeyward }
    }

    var hasStatic: Bool {
        contains { $0.name.tokenKind == .staticKeyword }
    }

    var accessLevelModifier: DeclModifierSyntax? {
        first { modifier in
            switch modifier.name.tokenKind {
            case .openKeyward,
                .publicKeyword,
                .internalKeyword,
                .fileprivateKeyword,
                .privateKeyword:
                return true

            default:
                return false
            }
        }
    }
}
