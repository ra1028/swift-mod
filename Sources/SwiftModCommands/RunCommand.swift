import ArgumentParser
import Foundation
import SwiftModCore
import TSCBasic

public struct RunCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Runs modification"
    )

    @Option(name: .shortAndLong)
    private var mode: Mode = .modify

    @Option(name: .shortAndLong)
    private var configuration: AbsolutePath?

    @Argument
    private var paths: [AbsolutePath]

    public init() {}

    public func run() throws {
        let runner = RunCommandRunner(
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
