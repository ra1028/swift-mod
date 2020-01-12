import SwiftModCommands
import SwiftModCore
import TSCBasic
import XCTest

final class RulesCommandTests: XCTestCase {
    func testArguments() throws {
        let options = try parseOptions(RulesCommand(), arguments: ["--detail", "test"])
        XCTAssertEqual(options.detailRuleIdentifier, "test")
    }

    func testRun() throws {
        let options = RulesCommand.Options(detailRuleIdentifier: nil)
        let command = RulesCommand()
        let exitCode = try command.run(with: options)

        XCTAssertEqual(exitCode, 0)
    }

    func testRunWithDetail() throws {
        let options = RulesCommand.Options(detailRuleIdentifier: Configuration.allRules.first?.description.identifier)
        let command = RulesCommand()
        let exitCode = try command.run(with: options)

        XCTAssertEqual(exitCode, 0)
    }
}
