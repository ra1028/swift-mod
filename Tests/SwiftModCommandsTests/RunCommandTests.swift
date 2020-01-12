import SwiftModCommands
import SwiftModCore
import SwiftModRules
import TSCBasic
import XCTest
import Yams

final class RunCommandTests: XCTestCase {
    func testArguments() throws {
        let options = try parseOptions(RunCommand(), arguments: ["--dry-run", "--configuration", "/home/cwd/.swift-mod.yml", "--target", "test"])

        XCTAssertEqual(options.mode, .dryRun)
        XCTAssertEqual(options.configurationPath, AbsolutePath("/home/cwd/.swift-mod.yml"))
        XCTAssertEqual(options.targetName, "test")
    }

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
            targets: [
                "test": Target(
                    paths: [
                        RelativePath("./test/file.swift"),
                        RelativePath("./test/excluded/file.swift"),
                    ],
                    excludedPaths: [
                        RelativePath("./test/excluded/file.swift"),
                    ],
                    rules: [
                        DefaultAccessLevelRule(
                            options: DefaultAccessLevelRule.Options(
                                accessLevel: .public,
                                implicitInternal: false
                            ),
                            format: format
                        ),
                    ]
                ),
            ]
        )

        try fileSystem.createDirectory(AbsolutePath("/home/cwd/test/excluded"), recursive: true)
        try fileSystem.writeFileContents(
            AbsolutePath("/home/cwd/.swift-mod.yml"),
            bytes: ByteString(encodingAsUTF8: try YAMLEncoder().encode(configuration))
        )
        try fileSystem.writeFileContents(
            AbsolutePath("/home/cwd/test/file.swift"),
            bytes: #"let cat = "meow""#
        )
        try fileSystem.writeFileContents(
            AbsolutePath("/home/cwd/test/excluded/file.swift"),
            bytes: #"let dog = "woof""#
        )

        let options = RunCommand.Options(
            configurationPath: AbsolutePath("/home/cwd/.swift-mod.yml"),
            targetName: nil
        )

        let command = RunCommand(fileSystem: fileSystem, fileManager: fileManager, measure: measure)
        let exitCode = try command.run(with: options)

        XCTAssertEqual(exitCode, 0)
        XCTAssertEqual(
            try fileSystem.readFileContents(AbsolutePath("/home/cwd/test/file.swift")),
            #"public let cat = "meow""#
        )
        XCTAssertEqual(
            try fileSystem.readFileContents(AbsolutePath("/home/cwd/test/excluded/file.swift")),
            #"let dog = "woof""#
        )
    }
}
