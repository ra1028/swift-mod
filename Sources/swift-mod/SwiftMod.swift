import ArgumentParser
import SwiftModCommands

@main
struct SwiftMod: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-mod",
        abstract: "Modifies Swift source code with rules",
        subcommands: [
            RunCommand.self,
            InitCommand.self,
            RulesCommand.self,
        ],
        defaultSubcommand: RunCommand.self
    )
}
