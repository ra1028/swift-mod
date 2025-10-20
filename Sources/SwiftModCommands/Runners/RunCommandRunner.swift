import Foundation
import SwiftModCore
import SwiftParser
import SwiftSyntax
import TSCBasic
import Yams

internal struct RunCommandRunner: @unchecked Sendable {
    enum Error: Swift.Error, CustomStringConvertible {
        case readOrParseFileFailed(path: AbsolutePath, error: Swift.Error)
        case writeFileContentsFailed(path: AbsolutePath, error: Swift.Error)
        case loadConfigurationFilePathFailed

        var description: String {
            switch self {
            case .readOrParseFileFailed(let path, let error):
                return """
                    Unable to parse file '\(path)'.

                    DETAILS:
                    \(String(error).offsetBeforeEachLines(2))
                    """

            case .writeFileContentsFailed(let path, let error):
                return """
                    Unable to write file contents to '\(path)'.

                    DETAILS:
                    \(String(error).offsetBeforeEachLines(2))
                    """

            case .loadConfigurationFilePathFailed:
                return "Could not load configuration file"
            }
        }
    }

    let configuration: AbsolutePath?
    let mode: Mode
    let paths: [AbsolutePath]
    let fileSystem: FileSystem
    let fileManager: FileManagerProtocol
    let measure: Measure

    func run() throws {
        let configurationPath = try configuration ?? fileSystem.currentWorkingDirectory.unwrapped(or: Error.loadConfigurationFilePathFailed)
        let configuration = try loadConfiguration(at: configurationPath)
        let results = try measure.run { () -> [ModifyResult] in
            return try [
                modify(rules: configuration.rules)
            ]
        }

        let numberOfModifiedFiles = results.value.reduce(0) { $0 + $1.numberOfModifiedFiles }
        let numberOfTotalFiles = results.value.reduce(0) { $0 + $1.numberOfTotalFiles }
        let message = "\(numberOfModifiedFiles)/\(numberOfTotalFiles) file\(numberOfModifiedFiles > 1 ? "s" : "") in \(results.time.formattedString())\n"

        switch mode {
        case .modify:
            InteractiveWriter.stdout.write("Completed modification " + message, inColor: .green)

        case .dryRun:
            InteractiveWriter.stdout.write("Completed dry run modification " + message, inColor: .green)

        case .check:
            let isFailed = numberOfModifiedFiles > 0
            InteractiveWriter.stdout.write("Completed check modification " + message, inColor: isFailed ? .red : .green)
        }
    }
}

private extension RunCommandRunner {
    struct ModifyResult {
        var numberOfModifiedFiles = 0
        var numberOfTotalFiles = 0
        var errors = [Swift.Error]()
    }

    func modify(rules: [AnyRule]) throws -> ModifyResult {
        let pathIterator = SwiftFileIterator(
            fileSystem: fileSystem,
            fileManager: fileManager,
            paths: paths
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
                        source = try fileSystem.readFileContents(path).cString
                        syntax = Syntax(Parser.parse(source: source))
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
