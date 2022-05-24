import TSCBasic
import ArgumentParser
import Foundation
import SwiftModCore

public struct ModCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "swift-mod",
        abstract: "Modifies Swift source code with rules",
        subcommands: [
            InitCommand.self,
            RulesCommand.self
        ]
    )

    @Option(name: .shortAndLong)
    private var mode: Mode = .modify

    @Option(name: .shortAndLong)
    private var configuration: AbsolutePath?

    @Argument
    private var paths: [AbsolutePath]

    public init() {}

    public func run() throws {
        let runner = ModCommandRunner(
            configuration: configuration,
            mode: mode,
            paths: paths,
            fileSystem: localFileSystem,
            fileManager: FileManager.default,
            measure: Measure()
        )
        try runner.run()
    }
}
