import SwiftModCore
import SwiftModRules
import TSCBasic
import XCTest
import Yams

@testable import SwiftModCommands

final class RunCommandRunnerTests: XCTestCase {
    func testRun() throws {
        let fileSystem = InMemoryFileSystem()
        let fileManager = InMemoryFileManager(fileSystem: fileSystem)
        let measure = Measure { Date(timeIntervalSince1970: 0) }
        let format = Format(
            indent: .spaces(4),
            lineBreakBeforeEachArgument: true
        )
        let configuration = Configuration(
            format: format,
            rules: [
                DefaultAccessLevelRule(
                    options: DefaultAccessLevelRule.Options(
                        accessLevel: .public,
                        implicitInternal: false
                    ),
                    format: format
                )
            ]
        )
        let configurationPath = try AbsolutePath(validating: "/home/cwd/.swift-mod.yml")

        try fileSystem.createDirectory(AbsolutePath(validating: "/home/cwd/test"), recursive: true)
        try fileSystem.writeFileContents(
            configurationPath,
            bytes: ByteString(encodingAsUTF8: try YAMLEncoder().encode(configuration))
        )
        try fileSystem.writeFileContents(
            AbsolutePath(validating: "/home/cwd/test/file1.swift"),
            bytes: #"let cat = "meow""#
        )
        try fileSystem.writeFileContents(
            AbsolutePath(validating: "/home/cwd/test/file2.swift"),
            bytes: #"let dog = "woof""#
        )

        let runner = RunCommandRunner(
            configuration: configurationPath,
            mode: .modify,
            paths: [
                try AbsolutePath(validating: "/home/cwd/test/file1.swift"),
                try AbsolutePath(validating: "/home/cwd/test/file2.swift"),
            ],
            fileSystem: fileSystem,
            fileManager: fileManager,
            measure: measure
        )
        try runner.run()

        XCTAssertEqual(
            try fileSystem.readFileContents(AbsolutePath(validating: "/home/cwd/test/file1.swift")),
            #"public let cat = "meow""#
        )
        XCTAssertEqual(
            try fileSystem.readFileContents(AbsolutePath(validating: "/home/cwd/test/file2.swift")),
            #"public let dog = "woof""#
        )
    }
}
