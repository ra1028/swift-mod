import SwiftSyntax

public extension TokenSyntax {
    func appendingLeadingTrivia(_ trivia: Trivia, condition: Bool = true) -> TokenSyntax {
        withLeadingTrivia(leadingTrivia + trivia, condition: condition)
    }

    func appendingTrailingTrivia(_ trivia: Trivia, condition: Bool = true) -> TokenSyntax {
        withTrailingTrivia(trailingTrivia + trivia, condition: condition)
    }

    func withLeadingTrivia(_ leadingTrivia: Trivia, condition: Bool) -> TokenSyntax {
        if condition {
            return with(\.leadingTrivia, leadingTrivia)
        }
        else {
            return self
        }
    }

    func withTrailingTrivia(_ trailingTrivia: Trivia, condition: Bool) -> TokenSyntax {
        if condition {
            return with(\.trailingTrivia, trailingTrivia)
        }
        else {
            return self
        }
    }
}
