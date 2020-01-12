import SwiftModCore
import TSCUtility
import XCTest

final class ToolTests: XCTestCase {
    class TestCommand: Command {
        typealias Options = Int

        class var description: CommandDescription<Int> {
            CommandDescription(name: "test", usage: "", overview: "", defaultOptions: 0)
        }

        func defineArguments(parser: ArgumentParser, binder: ArgumentBinder<Int>) {
            binder.bind(
                option: parser.add(
                    option: "--exit-code",
                    kind: Int.self
                ),
                to: { exitCode, specidied in
                    exitCode = specidied
                }
            )
        }

        func run(with options: Int) throws -> Int32 {
            Int32(options)
        }
    }

    final class TestSubCommand: TestCommand {
        override class var description: CommandDescription<Int> {
            CommandDescription(name: "sub", usage: "", overview: "", defaultOptions: 0)
        }

        override func run(with options: Int) throws -> Int32 {
            Int32(options * 2)
        }
    }

    func testRunCommand() {
        let tool = Tool(command: TestCommand())
        let exitCode = tool.run(arguments: ["tool-name", "--exit-code", "123"])
        XCTAssertEqual(exitCode, 123)
    }

    func testRunMainCommandAsSubCommand() {
        let tool = Tool(command: TestCommand())
        let exitCode = tool.run(arguments: ["tool-name", "test", "--exit-code", "234"])
        XCTAssertEqual(exitCode, 234)
    }

    func testRunSubCommand() {
        let tool = Tool(command: TestCommand())
        tool.add(command: TestSubCommand())
        let exitCode = tool.run(arguments: ["tool-name", "sub", "--exit-code", "345"])
        XCTAssertEqual(exitCode, 345 * 2)
    }

    func testVersion() {
        let tool = Tool(command: TestCommand())
        let exitCode = tool.run(arguments: ["--version"])
        XCTAssertEqual(exitCode, 0)
    }
}
