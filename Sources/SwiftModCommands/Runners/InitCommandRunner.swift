import TSCBasic
import SwiftModCore
import Yams

internal struct InitCommandRunner {
    enum Error: Swift.Error, CustomStringConvertible {
        case loadOutputPathFailed
        case writeFailed(path: AbsolutePath, error: Swift.Error)
        case alreadyExists(path: AbsolutePath)

        var description: String {
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

    let output: AbsolutePath?
    let fileSystem: FileSystem
    let fileManager: FileManagerProtocol

    func run() throws {
        let outputPath = try output ?? fileSystem.currentWorkingDirectory .unwrapped(or: Error.loadOutputPathFailed)

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
        }
        catch let error as Error {
            throw error
        }
        catch {
            throw Error.writeFailed(path: outputPath, error: error)
        }

    }
}
