import ArgumentParser
import Foundation
import SwiftModCore
import TSCBasic

public struct RunCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Runs modification."
    )

    @Option(
        name: .shortAndLong,
        help: "Overrides running mode: \(Mode.allCases.map(\.rawValue).joined(separator: "|"))."
    )
    private var mode: Mode = .modify

    @Option(
        name: .shortAndLong,
        help: "The path to a configuration file."
    )
    private var configuration: AbsolutePath?

    @Argument(
        help: "Zero or more input filenames."
    )
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
