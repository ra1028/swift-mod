import SwiftSyntax

public extension Indent {
    var trivia: Trivia {
        switch self {
        case .spaces(let spaces):
            return .spaces(spaces)

        case .tab:
            return .tab
        }
    }
}
