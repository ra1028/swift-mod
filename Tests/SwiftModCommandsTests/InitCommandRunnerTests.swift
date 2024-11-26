import SwiftModCore
import TSCBasic
import XCTest
import Yams

@testable import SwiftModCommands

final class InitCommandTests: XCTestCase {
    func testRun() throws {
        let fileSystem = InMemoryFileSystem()
        let fileManager = InMemoryFileManager(fileSystem: fileSystem)
        let output = try AbsolutePath(validating: "/home/cwd/output/.swift-mod.yml")
        let runner = InitCommandRunner(
            output: output,
            fileSystem: fileSystem,
            fileManager: fileManager
        )

        try runner.run()

        XCTAssertEqual(
            try fileSystem.readFileContents(output),
            ByteString(encodingAsUTF8: try YAMLEncoder().encode(Configuration.template))
        )
    }
}
