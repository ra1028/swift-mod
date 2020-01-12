import SwiftModCommands
import SwiftModCore
import TSCBasic
import TSCUtility
import XCTest
import Yams

final class InitCommandTests: XCTestCase {
    func testArguments() throws {
        let options = try parseOptions(InitCommand(), arguments: ["--output", "/test/path"])
        XCTAssertEqual(options.outputPath?.pathString, "/test/path")
    }

    func testRun() throws {
        let fileSystem = InMemoryFileSystem()
        let fileManager = InMemoryFileManager(fileSystem: fileSystem)

        let options = InitCommand.Options(outputPath: AbsolutePath("/home/cwd/output/.swift-mod.yml"))
        let command = InitCommand(fileSystem: fileSystem, fileManager: fileManager)
        let exitCode = try command.run(with: options)

        XCTAssertEqual(exitCode, 0)
        XCTAssertEqual(try fileSystem.readFileContents(AbsolutePath("/home/cwd/output/.swift-mod.yml")), ByteString(encodingAsUTF8: try YAMLEncoder().encode(Configuration.template)))
    }
}
