import Foundation
import SwiftModCore
import SwiftModRules
import SwiftSyntax
import SwiftSyntaxParser
import TSCBasic
import TSCUtility
import Yams

public struct RunCommand: Command {
    public struct Options {
        public var mode: Mode
        public var configurationPath: AbsolutePath?
        public var paths: [AbsolutePath]

        public init(
            mode: Mode = .modify,
            configurationPath: AbsolutePath? = nil,
            paths: [AbsolutePath] = []
        ) {
            self.mode = mode
            self.configurationPath = configurationPath
            self.paths = paths
        }
    }

    public enum Mode {
        case modify
        case dryRun
        case check
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case readOrParseFileFailed(path: AbsolutePath, error: Swift.Error)
        case writeFileContentsFailed(path: AbsolutePath, error: Swift.Error)
        case loadConfigurationFilePathFailed

        public var description: String {
            switch self {
            case .readOrParseFileFailed(let path, let error):
                return """
                    Unable to parse file '\(path.prettyPath())'.

                    DETAILS:
                    \(String(error).offsetBeforeEachLines(2))
                    """

            case .writeFileContentsFailed(let path, let error):
                return """
                    Unable to write file contents to '\(path.prettyPath())'.

                    DETAILS:
                    \(String(error).offsetBeforeEachLines(2))
                    """

            case .loadConfigurationFilePathFailed:
                return "Could not load configuration file"
            }
        }
    }

    public static let description = CommandDescription(
        name: "run",
        usage: "[options]",
        overview: "Modifies Swift source code by rules",
        defaultOptions: Options()
    )

    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol
    private let measure: Measure

    public init(
        fileSystem: FileSystem = localFileSystem,
        fileManager: FileManagerProtocol = FileManager.default,
        measure: Measure = Measure()
    ) {
        self.fileSystem = fileSystem
        self.fileManager = fileManager
        self.measure = measure
    }

    public func defineArguments(parser: ArgumentParser, binder: ArgumentBinder<Options>) {
        binder.bind(
            option: parser.add(
                option: "--configuration",
                shortName: "-c",
                kind: PathArgument.self,
                usage: "The path to a configuration Yaml file",
                completion: .filename
            ),
            to: { options, configuration in
                options.configurationPath = configuration.path
            }
        )

        binder.bind(
            option: parser.add(
                option: "--dry-run",
                kind: Bool.self,
                usage: "Run without actually changing any files"
            ),
            to: { options, _ in
                options.mode = .dryRun
            }
        )

        binder.bind(
            option: parser.add(
                option: "--check",
                kind: Bool.self,
                usage: "Dry run that an error occurs if the any files should be changed"
            ),
            to: { options, _ in
                options.mode = .check
            }
        )

        binder.bindArray(
            positional: parser.add(
                positional: "paths",
                kind: [PathArgument].self,
                strategy: .remaining,
                usage: "A list of files that to be modified",
                completion: .filename
            ),
            to: { options, paths in
                options.paths = paths.map(\.path)
            }
        )
    }

    public func run(with options: Options) throws -> Int32 {
        let configurationPath =
            try options.configurationPath
            ?? fileSystem.currentWorkingDirectory
            .unwrapped(or: Error.loadConfigurationFilePathFailed)
        let configuration = try loadConfiguration(at: configurationPath)
        let results = try measure.run { () -> [ModifyResult] in
            return try [
                modify(rules: configuration.rules, options: options)
            ]
        }

        let numberOfModifiedFiles = results.value.reduce(0) { $0 + $1.numberOfModifiedFiles }
        let numberOfTotalFiles = results.value.reduce(0) { $0 + $1.numberOfTotalFiles }
        let message = "\(numberOfModifiedFiles)/\(numberOfTotalFiles) file\(numberOfModifiedFiles > 1 ? "s" : "") in \(results.time.formattedString())\n"

        switch options.mode {
        case .modify:
            InteractiveWriter.stdout.write("Completed modification " + message, inColor: .green)
            return 0

        case .dryRun:
            InteractiveWriter.stdout.write("Completed dry run modification " + message, inColor: .green)
            return 0

        case .check:
            let isFailed = numberOfModifiedFiles > 0
            InteractiveWriter.stdout.write("Completed check modification " + message, inColor: isFailed ? .red : .green)
            return isFailed ? 1 : 0
        }
    }
}

private extension RunCommand {
    struct ModifyResult {
        var numberOfModifiedFiles = 0
        var numberOfTotalFiles = 0
        var errors = [Swift.Error]()
    }

    func modify(
        rules: [AnyRule],
        options: Options
    ) throws -> ModifyResult {
        let pathIterator = SwiftFileIterator(
            fileSystem: fileSystem,
            fileManager: fileManager,
            paths: options.paths
        )
        let pipeline = RulePipeline(
            rules.lazy
                .filter { $0.isEnabled }
                .sorted { type(of: $0).description.priority > type(of: $1).description.priority }
        )
        let writer = InteractiveWriter.stdout
        writer.write("Applying rules ...")

        defer { writer.write(" done\n") }

        let result = Atomic(ModifyResult())
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        for path in pathIterator {
            group.enter()
            queue.async(group: group) {
                defer { group.leave() }

                do {
                    result.modify { $0.numberOfTotalFiles += 1 }

                    let source: String
                    let syntax: Syntax
                    let modifiedSyntax: Syntax

                    do {
                        source = try self.fileSystem.readFileContents(path).cString
                        syntax = try Syntax(SyntaxParser.parse(source: source))
                        modifiedSyntax = pipeline.visit(syntax)
                    }
                    catch {
                        throw Error.readOrParseFileFailed(path: path, error: error)
                    }

                    let modifiedSource = modifiedSyntax.description
                    let isModified = source != modifiedSource

                    if isModified && options.mode == .modify {
                        try self.rewriteFileContents(path: path, modifiedSource: modifiedSource)
                    }

                    if isModified {
                        result.modify { $0.numberOfModifiedFiles += 1 }
                    }
                }
                catch {
                    result.modify { $0.errors.append(error) }
                }
            }
        }

        group.wait()

        if let firstError = result.value.errors.first {
            throw firstError
        }

        return result.value
    }

    func rewriteFileContents(path: AbsolutePath, modifiedSource: String) throws {
        do {
            try fileSystem.writeFileContents(path) { stream in
                stream.write(modifiedSource)
            }
        }
        catch {
            throw Error.writeFileContentsFailed(path: path, error: error)
        }
    }

    func loadConfiguration(at path: AbsolutePath) throws -> Configuration {
        let path =
            fileSystem.isDirectory(path)
            ? path.appending(component: Configuration.defaultFileName)
            : path

        let yaml: String

        do {
            yaml = try fileSystem.readFileContents(path).cString
        }
        catch {
            throw ConfigurationError.loadFailed(path: path, error: error)
        }

        do {
            return try YAMLDecoder().decode(from: yaml)
        }
        catch let error as ConfigurationError {
            throw error
        }
        catch let error as DecodingError {
            throw ConfigurationError.decodeFailed(error: error.underlyingError ?? error)
        }
        catch {
            throw ConfigurationError.invalidSetting(error: error)
        }
    }
}

private extension Double {
    func formattedString() -> String {
        String(format: "%gs", (self * 100).rounded() / 100)
    }
}
