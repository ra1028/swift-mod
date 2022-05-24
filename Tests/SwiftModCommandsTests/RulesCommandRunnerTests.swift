@testable import SwiftModCommands
import XCTest
import SwiftModCore
import SwiftModRules

final class RulesCommandTests: XCTestCase {
    func testRun() throws {
        let writer = InMemoryInteractiveWriter()
        let runner = RulesCommandRunner(
            rule: nil,
            writer: writer
        )

        try runner.run()

        XCTAssertEqual(
            writer.inputs,
            runner.overviewLines().map {
                InMemoryInteractiveWriter.Input(string: $0, color: .noColor, bold: false)
            }
        )
    }

    func testRunWithDetail() throws {
        let writer = InMemoryInteractiveWriter()
        let ruleName = DefaultAccessLevelRule.description.name
        let runner = RulesCommandRunner(rule: ruleName, writer: writer)

        try runner.run()

        XCTAssertEqual(
            writer.inputs,
            try runner.definitionLines(ruleName: ruleName).map {
                InMemoryInteractiveWriter.Input(string: $0, color: .noColor, bold: false)
            }
        )
    }
}
