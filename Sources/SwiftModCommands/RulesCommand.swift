import SwiftModCore
import TSCBasic
import TSCUtility
import Yams

public struct RulesCommand: Command {
    public struct Options {
        public var detailRuleIdentifier: String?

        public init(detailRuleIdentifier: String? = nil) {
            self.detailRuleIdentifier = detailRuleIdentifier
        }
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case unknownRuleIdentifierSpecified(identifier: String)

        public var description: String {
            switch self {
            case .unknownRuleIdentifierSpecified(let identifier):
                return "Unknown rule identifier `\(identifier)` specified"
            }
        }
    }

    public static let description = CommandDescription(
        name: "rules",
        usage: "[options]",
        overview: "Display the list of rules",
        defaultOptions: Options()
    )

    public init() {}

    public func defineArguments(parser: ArgumentParser, binder: ArgumentBinder<Options>) {
        binder.bind(
            option: parser.add(
                option: "--detail",
                shortName: "-d",
                kind: String.self,
                usage: "A rule identifier to displaying detailed description"
            ),
            to: { options, detailRuleIdentifier in
                options.detailRuleIdentifier = detailRuleIdentifier
            }
        )
    }

    public func run(with options: Options) throws -> Int32 {
        if let detailRuleIdentifier = options.detailRuleIdentifier {
            guard let rule = Configuration.allRules.first(where: { $0.description.name == detailRuleIdentifier }) else {
                throw Error.unknownRuleIdentifierSpecified(identifier: detailRuleIdentifier)
            }

            let description = rule.description
            let writer = InteractiveWriter.stdout
            let offset = 2

            writer.write("NAME:\n")
            writer.write(description.name.offsetBeforeEachLines(offset))
            writer.write("\n\n")
            writer.write("OVERVIEW:\n")
            writer.write(description.overview.offsetBeforeEachLines(offset))
            writer.write("\n\n")
            writer.write("EXAMPLE OPTIONS:\n")
            writer.write(try YAMLEncoder().encode(description.exampleOptions).offsetBeforeEachLines(offset))
            writer.write("\n")
            writer.write("EXAMPLE BEFORE:\n")
            writer.write(description.exampleBefore.offsetBeforeEachLines(offset))
            writer.write("\n\n")
            writer.write("EXAMPLE AFTER:\n")
            writer.write(description.exampleAfter.offsetBeforeEachLines(offset))
            writer.write("\n")

            return 0
        }
        else {
            let allRuleDescriptions = Configuration.allRules.map { $0.description }
            let maxIdentifierWidth =
                allRuleDescriptions.lazy
                .map { $0.name.count }
                .max() ?? 0
            let writer = InteractiveWriter.stdout

            writer.write("RULES:\n")

            for description in allRuleDescriptions {
                writer.write(
                    description.name
                        .padding(toLength: maxIdentifierWidth + 4, withPad: " ", startingAt: 0)
                        .offsetBeforeEachLines(2)
                )
                writer.write(description.overview)
                writer.write("\n")
            }

            return 0
        }
    }
}
