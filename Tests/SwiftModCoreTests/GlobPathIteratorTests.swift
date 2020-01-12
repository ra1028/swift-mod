import SwiftModCore
import TSCBasic
import XCTest

final class GlobPathIteratorTests: XCTestCase {
    func testGlob() throws {
        let fileSystem = localFileSystem
        let fileManager = FileManager.default

        let currentFilePath = AbsolutePath(#file)
        let path = currentFilePath
            .parentDirectory
            .parentDirectory
            .appending(components: "**", "\(currentFilePath.basenameWithoutExt).*")
        let iterator = GlobPathIterator(fileSystem: fileSystem, fileManager: fileManager, path: path)

        XCTAssertEqual(iterator.next(), currentFilePath)
        XCTAssertNil(iterator.next())
    }
}
