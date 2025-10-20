import Foundation
import SwiftModCore
import SwiftParser
import XCTest

func assertRuleDescription(_ rule: AnyRule, file: StaticString = #filePath, line: UInt = #line) throws {
    let description = type(of: rule).description
    let encodedOptions = try? JSONEncoder().encode(description.exampleOptions)
    let exampleSyntax = Parser.parse(source: description.exampleBefore)
    let exampleModified = rule.rewriter().visit(exampleSyntax).description

    XCTAssertFalse(description.name.isEmpty, file: file, line: line)
    XCTAssertFalse(description.overview.isEmpty, file: file, line: line)
    XCTAssertNotNil(encodedOptions, file: file, line: line)
    XCTAssertEqual(exampleModified, description.exampleAfter, file: file, line: line)
}

func assertRule(_ rule: AnyRule, source: String, expected: String, file: StaticString = #filePath, line: UInt = #line) throws {
    let syntax = Parser.parse(source: source)
    let modified = rule.rewriter().visit(syntax).description
    XCTAssertEqual(modified, expected, file: file, line: line)
}
