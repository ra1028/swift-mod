#if !canImport(ObjectiveC)
import XCTest

extension GlobPathIteratorTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__GlobPathIteratorTests = [
        ("testGlob", testGlob),
    ]
}

extension RuleSyntaxRewriterTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RuleSyntaxRewriterTests = [
        ("testIgnoreCommentForCodeBlockItem", testIgnoreCommentForCodeBlockItem),
        ("testIgnoreCommentForMemberDeclListItem", testIgnoreCommentForMemberDeclListItem),
    ]
}

extension ToolTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ToolTests = [
        ("testRunCommand", testRunCommand),
        ("testRunMainCommandAsSubCommand", testRunMainCommandAsSubCommand),
        ("testRunSubCommand", testRunSubCommand),
        ("testVersion", testVersion),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GlobPathIteratorTests.__allTests__GlobPathIteratorTests),
        testCase(RuleSyntaxRewriterTests.__allTests__RuleSyntaxRewriterTests),
        testCase(ToolTests.__allTests__ToolTests),
    ]
}
#endif
