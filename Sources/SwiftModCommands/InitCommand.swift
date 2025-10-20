import ArgumentParser
import Foundation
import TSCBasic

public struct InitCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Generates a modify configuration file."
    )

    @Option(
        name: .shortAndLong,
        help: "An output for the configuration file to be generated."
    )
    private var output: AbsolutePath?

    public init() {}

    public func run() throws {
        let runner = InitCommandRunner(
            output: output,
            fileSystem: localFileSystem,
            fileManager: FileManager.default
        )
        try runner.run()
    }
}
