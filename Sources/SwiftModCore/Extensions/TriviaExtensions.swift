import SwiftSyntax

public extension Trivia {
    var numberOfNewlines: Int {
        reduce(0) { result, piece in
            switch piece {
            case .newlines(let count):
                return result + count

            default:
                return result
            }
        }
    }

    var indentation: Trivia {
        Trivia(
            pieces: filter { piece in
                switch piece {
                case .spaces, .tabs:
                    return true

                default:
                    return false
                }
            }
        )
    }
}
