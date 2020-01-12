import XCTest

import SwiftModCommandsTests
import SwiftModCoreTests
import SwiftModRulesTests

var tests = [XCTestCaseEntry]()
tests += SwiftModCommandsTests.__allTests()
tests += SwiftModCoreTests.__allTests()
tests += SwiftModRulesTests.__allTests()

XCTMain(tests)
