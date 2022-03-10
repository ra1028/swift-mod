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
        public var targetName: String?

        public init(
            mode: Mode = .modify,
            configurationPath: AbsolutePath? = nil,
            targetName: String? = nil
        ) {
            self.mode = mode
            self.configurationPath = configurationPath
            self.targetName = targetName
        }
    }

    public enum Mode {
        case modify
        case dryRun
        case check
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case unknownTargetSpecified(targetName: String)
        case readOrParseFileFailed(path: AbsolutePath, error: Swift.Error)
        case writeFileContentsFailed(path: AbsolutePath, error: Swift.Error)
        case loadConfigurationFilePathFailed

        public var description: String {
            switch self {
            case .unknownTargetSpecified(let targetName):
                return "Unknown target name '\(targetName)' specified"

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
                option: "--target",
                shortName: "-t",
                kind: String.self,
                usage: "The target name to be run partially"
            ),
            to: { options, targetName in
                options.targetName = targetName
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
    }

    public func run(with options: Options) throws -> Int32 {
        let configurationPath =
            try options.configurationPath
            ?? fileSystem.currentWorkingDirectory
            .unwrapped(or: Error.loadConfigurationFilePathFailed)
        let configuration = try loadConfiguration(at: configurationPath)
        let results = try measure.run { () -> [ModifyResult] in
            if let targetName = options.targetName {
                guard let target = configuration.targets[targetName] else {
                    throw Error.unknownTargetSpecified(targetName: targetName)
                }

                return try [
                    modify(target: target, targetName: targetName, configurationPath: configurationPath, mode: options.mode)
                ]
            }
            else {
                return try configuration.targets.map { target in
                    try modify(target: target.value, targetName: target.key, configurationPath: configurationPath, mode: options.mode)
                }
            }
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
        target: Target,
        targetName: String,
        configurationPath: AbsolutePath,
        mode: Mode
    ) throws -> ModifyResult {
        let pathIterator = SwiftFileIterator(
            fileSystem: fileSystem,
            fileManager: fileManager,
            referencePath: fileSystem.isDirectory(configurationPath)
                ? configurationPath
                : configurationPath.parentDirectory,
            paths: target.paths,
            excludedPaths: target.excludedPaths
        )
        let pipeline = RulePipeline(
            target.rules.lazy
                .filter { $0.isEnabled }
                .sorted { type(of: $0).description.priority > type(of: $1).description.priority }
        )

        let writer = InteractiveWriter.stdout
        writer.write("Modifying target - \(targetName) ...")
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

                    if isModified && mode == .modify {
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
