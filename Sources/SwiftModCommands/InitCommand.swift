import ArgumentParser
import Foundation
import TSCBasic

public struct InitCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Generates a modify configuration file"
    )

    @Option(name: .shortAndLong)
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
