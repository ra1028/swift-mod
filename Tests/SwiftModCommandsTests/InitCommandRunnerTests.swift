@testable import SwiftModCommands
import TSCBasic
import SwiftModCore
import XCTest
import Yams

final class InitCommandTests: XCTestCase {
    func testRun() throws {
        let fileSystem = InMemoryFileSystem()
        let fileManager = InMemoryFileManager(fileSystem: fileSystem)
        let output = AbsolutePath("/home/cwd/output/.swift-mod.yml")
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
