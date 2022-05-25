import SwiftModCore
import Yams

internal struct RulesCommandRunner {
    enum Error: Swift.Error, CustomStringConvertible {
        case unknownRuleSpecified(name: String)

        var description: String {
            switch self {
            case .unknownRuleSpecified(let name):
                return "Unknown rule name `\(name)` is specified"
            }
        }
    }

    let rule: String?
    let writer: InteractiveWriterProtocol

    func definitionLines(ruleName: String) throws -> [String] {
        guard let rule = Configuration.allRules.first(where: { $0.description.name == ruleName }) else {
            throw Error.unknownRuleSpecified(name: ruleName)
        }

        let description = rule.description
        let offset = 2

        return try [
            "NAME:\n",
            description.name.offsetBeforeEachLines(offset),
            "\n\n",
            "OVERVIEW:\n",
            description.overview.offsetBeforeEachLines(offset),
            "\n\n",
            "EXAMPLE OPTIONS:\n",
            YAMLEncoder().encode(description.exampleOptions).offsetBeforeEachLines(offset),
            "\n",
            "EXAMPLE BEFORE:\n",
            description.exampleBefore.offsetBeforeEachLines(offset),
            "\n\n",
            "EXAMPLE AFTER:\n",
            description.exampleAfter.offsetBeforeEachLines(offset),
            "\n",
        ]
    }

    func overviewLines() -> [String] {
        let allRuleDescriptions = Configuration.allRules.map { $0.description }
        let maxIdentifierWidth =
            allRuleDescriptions.lazy
            .map { $0.name.count }
            .max() ?? 0

        return ["RULES:\n"]
            + allRuleDescriptions.flatMap { description in
                [
                    description.name
                        .padding(toLength: maxIdentifierWidth + 4, withPad: " ", startingAt: 0)
                        .offsetBeforeEachLines(2),
                    description.overview,
                    "\n",
                ]
            }
    }

    func run() throws {
        let lines = try rule.map(definitionLines) ?? overviewLines()

        for line in lines {
            writer.write(line)
        }
    }
}
