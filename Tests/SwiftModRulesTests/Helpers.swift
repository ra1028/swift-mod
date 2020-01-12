import Foundation
import SwiftModCore
import SwiftSyntax
import XCTest

func assertRuleDescription(_ rule: AnyRule, file: StaticString = #file, line: UInt = #line) throws {
    let description = type(of: rule).description
    let encodedOptions = try? JSONEncoder().encode(description.exampleOptions)
    let exampleSyntax = try SyntaxParser.parse(source: description.exampleBefore)
    let exampleModified = rule.rewriter().visit(exampleSyntax).description

    XCTAssertFalse(description.identifier.isEmpty, file: file, line: line)
    XCTAssertFalse(description.overview.isEmpty, file: file, line: line)
    XCTAssertNotNil(encodedOptions, file: file, line: line)
    XCTAssertEqual(exampleModified, description.exampleAfter, file: file, line: line)
}

func assertRule(_ rule: AnyRule, source: String, expected: String, file: StaticString = #file, line: UInt = #line) throws {
    let syntax = try SyntaxParser.parse(source: source)
    let modified = rule.rewriter().visit(syntax).description
    XCTAssertEqual(modified, expected, file: file, line: line)
}
