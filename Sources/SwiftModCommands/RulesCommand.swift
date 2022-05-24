import ArgumentParser
import SwiftModCore

public struct RulesCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "rules",
        abstract: "Display the list of rules"
    )

    @Option
    private var rule: String?

    public init() {}

    public func run() throws {
        let runner = RulesCommandRunner(
            rule: rule,
            writer: InteractiveWriter.stdout
        )
        try runner.run()
    }
}
