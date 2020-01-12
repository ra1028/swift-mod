import Foundation
import SwiftModCore
import SwiftModRules
import TSCBasic
import TSCUtility
import Yams

public struct InitCommand: Command {
    public struct Options {
        public var outputPath: AbsolutePath?

        public init(outputPath: AbsolutePath? = nil) {
            self.outputPath = outputPath
        }
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case loadOutputPathFailed
        case writeFailed(path: AbsolutePath, error: Swift.Error)
        case alreadyExists(path: AbsolutePath)

        public var description: String {
            switch self {
            case .loadOutputPathFailed:
                return "Could not load output path"

            case .writeFailed(let path, let error):
                return """
                    Could not write configuration at '\(path.prettyPath())'

                    DETAILS:
                    \(String(error).offsetBeforeEachLines(2))
                    """

            case .alreadyExists(let path):
                return "A configuration file already exists at '\(path.prettyPath())'"
            }
        }
    }

    public static let description = CommandDescription(
        name: "init",
        usage: "[options]",
        overview: "Generates a modify configuration file",
        defaultOptions: Options()
    )

    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol

    public init(
        fileSystem: FileSystem = localFileSystem,
        fileManager: FileManagerProtocol = FileManager.default
    ) {
        self.fileSystem = fileSystem
        self.fileManager = fileManager
    }

    public func defineArguments(parser: ArgumentParser, binder: ArgumentBinder<Options>) {
        binder.bind(
            option: parser.add(
                option: "--output",
                shortName: "-o",
                kind: PathArgument.self,
                usage: "Path where the modify configuration should be generated",
                completion: .filename
            ),
            to: { options, output in
                options.outputPath = output.path
            }
        )
    }

    public func run(with options: Options) throws -> Int32 {
        let outputPath =
            try options.outputPath
            ?? fileSystem.currentWorkingDirectory
            .unwrapped(or: Error.loadOutputPathFailed)

        do {
            let outputPath =
                fileSystem.isDirectory(outputPath)
                ? outputPath.appending(component: Configuration.defaultFileName)
                : outputPath

            if fileSystem.exists(outputPath) {
                throw Error.alreadyExists(path: outputPath)
            }
            else {
                InteractiveWriter.stdout.write("Creating \(outputPath.prettyPath())\n")
                try fileSystem.createDirectory(outputPath.parentDirectory, recursive: true)
                fileManager.createFile(atPath: outputPath.pathString)
            }

            let configuration = Configuration.template
            let encoded = try YAMLEncoder().encode(configuration)
            try fileSystem.writeFileContents(outputPath) { buffer in
                buffer.write(encoded)
            }

            return 0
        }
        catch let error as Error {
            throw error
        }
        catch {
            throw Error.writeFailed(path: outputPath, error: error)
        }
    }
}
