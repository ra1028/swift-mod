import SwiftModCore
import SwiftModRules
import XCTest

final class DefaultMemberwiseInitializerRuleTests: XCTestCase {
    let defaultRule = DefaultMemberwiseInitializerRule(
        options: DefaultMemberwiseInitializerRule.Options(
            implicitInitializer: false,
            implicitInternal: true,
            ignoreClassesWithInheritance: false
        ),
        format: .default
    )

    func testDescription() throws {
        try assertRuleDescription(defaultRule)
    }

    func testIgnore() throws {
        try assertRule(
            defaultRule,
            source: """
                // swift-mod-ignore: defaultMemberwiseInitializer
                struct Struct {}
                """,
            expected: """
                // swift-mod-ignore: defaultMemberwiseInitializer
                struct Struct {}
                """
        )
    }

    func testStruct() throws {
        try assertRule(
            defaultRule,
            source: """
                public struct Struct {
                    static let staticProperty: Int = 0
                    static func staticFunction() -> Int { 0 }
                    var property1: Int
                    var property2: Int = 0
                    var property3 = 0
                    var property4: Int { 0 }
                    internal var property5: Int
                    var property6: Int?
                    var property7: Int!
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                }
                """,
            expected: """
                public struct Struct {
                    static let staticProperty: Int = 0
                    static func staticFunction() -> Int { 0 }
                    var property1: Int
                    var property2: Int = 0
                    var property3 = 0
                    var property4: Int { 0 }
                    internal var property5: Int
                    var property6: Int?
                    var property7: Int!
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }

                    public init(
                        property1: Int,
                        property2: Int = 0,
                        property5: Int,
                        property6: Int? = nil,
                        property7: Int? = nil
                    ) {
                        self.property1 = property1
                        self.property2 = property2
                        self.property5 = property5
                        self.property6 = property6
                        self.property7 = property7
                    }
                }
                """
        )
    }

    func testStructImplicitInitializer() throws {
        let rule = DefaultMemberwiseInitializerRule(
            options: DefaultMemberwiseInitializerRule.Options(
                implicitInitializer: true,
                implicitInternal: true,
                ignoreClassesWithInheritance: false
            ),
            format: .default
        )
        try assertRule(
            rule,
            source: """
                struct Struct {}
                """,
            expected: """
                struct Struct {}
                """
        )
    }

    func testClass() throws {
        try assertRule(
            defaultRule,
            source: """
                public class Class {
                    static let staticProperty: Int = 0
                    static func staticFunction() -> Int { 0 }
                    var property1: Int
                    var property2: Int = 0
                    var property3 = 0
                    var property4: Int { 0 }
                    internal var property5: Int
                    var property6: Int?
                    var property7: Int!
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                }
                """,
            expected: """
                public class Class {
                    static let staticProperty: Int = 0
                    static func staticFunction() -> Int { 0 }
                    var property1: Int
                    var property2: Int = 0
                    var property3 = 0
                    var property4: Int { 0 }
                    internal var property5: Int
                    var property6: Int?
                    var property7: Int!
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }

                    public init(
                        property1: Int,
                        property2: Int = 0,
                        property5: Int,
                        property6: Int? = nil,
                        property7: Int? = nil
                    ) {
                        self.property1 = property1
                        self.property2 = property2
                        self.property5 = property5
                        self.property6 = property6
                        self.property7 = property7
                    }
                }
                """
        )
    }

    func testClassImplicitInitializer() throws {
        let rule = DefaultMemberwiseInitializerRule(
            options: DefaultMemberwiseInitializerRule.Options(
                implicitInitializer: true,
                implicitInternal: true,
                ignoreClassesWithInheritance: false
            ),
            format: .default
        )
        try assertRule(
            rule,
            source: """
                class Class {}
                """,
            expected: """
                class Class {}
                """
        )
    }

    func testReserved() throws {
        try assertRule(
            defaultRule,
            source: """
                struct Struct {
                    var `optional`: Int
                    var `switch`: Int
                }
                """,
            expected: """
                struct Struct {
                    var `optional`: Int
                    var `switch`: Int

                    init(
                        `optional`: Int,
                        `switch`: Int
                    ) {
                        self.optional = `optional`
                        self.switch = `switch`
                    }
                }
                """
        )
    }

    func testNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                struct Struct {
                    var property: Int

                    init() {
                        property = 0
                    }
                }
                """,
            expected: """
                struct Struct {
                    var property: Int

                    init() {
                        property = 0
                    }
                }
                """
        )
    }

    func testPrivate() throws {
        try assertRule(
            defaultRule,
            source: """
                private struct Struct {
                    var property: Int
                }
                """,
            expected: """
                private struct Struct {
                    var property: Int

                    init(property: Int) {
                        self.property = property
                    }
                }
                """
        )
    }

    func testFilePrivate() throws {
        try assertRule(
            defaultRule,
            source: """
                fileprivate struct Struct {
                    var property: Int
                }
                """,
            expected: """
                fileprivate struct Struct {
                    var property: Int

                    init(property: Int) {
                        self.property = property
                    }
                }
                """
        )
    }

    func testIgnoreClassesWithInheritance() throws {
        let rule = DefaultMemberwiseInitializerRule(
            options: DefaultMemberwiseInitializerRule.Options(
                implicitInitializer: false,
                implicitInternal: true,
                ignoreClassesWithInheritance: true
            ),
            format: .default
        )

        try assertRule(
            rule,
            source: """
                class Class: Inheritance {
                    var property: Int
                }
                """,
            expected: """
                class Class: Inheritance {
                    var property: Int
                }
                """
        )
    }

    func testCustomFormat() throws {
        let rule = DefaultMemberwiseInitializerRule(
            options: DefaultMemberwiseInitializerRule.Options(
                implicitInitializer: false,
                implicitInternal: true,
                ignoreClassesWithInheritance: false
            ),
            format: Format(
                indent: .spaces(2),
                lineBreakBeforeEachArgument: false
            )
        )

        try assertRule(
            rule,
            source: """
                struct Struct {
                  var property1: Int
                  var property2: Int
                  var property3: Int
                }
                """,
            expected: """
                struct Struct {
                  var property1: Int
                  var property2: Int
                  var property3: Int

                  init(property1: Int, property2: Int, property3: Int) {
                    self.property1 = property1
                    self.property2 = property2
                    self.property3 = property3
                  }
                }
                """
        )
    }
}
