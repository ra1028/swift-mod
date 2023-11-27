import SwiftModRules
import XCTest

final class DefaultAccessLevelRuleTests: XCTestCase {
    let defaultRule = DefaultAccessLevelRule(
        options: DefaultAccessLevelRule.Options(
            accessLevel: .openOrPublic,
            implicitInternal: true
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
                // swift-mod-ignore: defaultAccessLevel
                struct Struct {}
                // swift-mod-ignore: defaultAccessLevel
                let variable = 0
                class Class {
                    // swift-mod-ignore: defaultAccessLevel
                    var property = 0
                }
                """,
            expected: """
                // swift-mod-ignore: defaultAccessLevel
                struct Struct {}
                // swift-mod-ignore: defaultAccessLevel
                let variable = 0
                open class Class {
                    // swift-mod-ignore: defaultAccessLevel
                    var property = 0
                }
                """
        )
    }

    func testStruct() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                struct Struct {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var stored: Int
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init(variable: Int) { self.variable = variable }
                }
                """,
            expected: """
                @available(swift 5.1)
                public struct Struct {
                    public typealias TypeAlias = Int
                    public static let staticStored = 0
                    public static func staticFunction() -> Int { 0 }
                    public var stored: Int
                    public var computed: Int { 0 }
                    internal var internalProperty: Int
                    public func function(value: Int) -> Int { value }
                    public subscript (value: Int) -> Int { value }
                    public init(variable: Int) { self.variable = variable }
                }
                """
        )
    }

    func testStructNested() throws {
        try assertRule(
            defaultRule,
            source: """
                struct Struct {
                    struct Nested {
                        var stored: Int
                    }
                }
                """,
            expected: """
                public struct Struct {
                    public struct Nested {
                        public var stored: Int
                    }
                }
                """
        )
    }

    func testStructNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal struct Struct {
                    struct Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """,
            expected: """
                internal struct Struct {
                    struct Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """
        )
    }

    func testClass() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                class Class {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var stored: Int
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    final func finalFunction(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init(variable: Int) { self.variable = variable }
                }
                """,
            expected: """
                @available(swift 5.1)
                open class Class {
                    public typealias TypeAlias = Int
                    public static let staticStored = 0
                    public static func staticFunction() -> Int { 0 }
                    public var stored: Int
                    open var computed: Int { 0 }
                    internal var internalProperty: Int
                    open func function(value: Int) -> Int { value }
                    public final func finalFunction(value: Int) -> Int { value }
                    open subscript (value: Int) -> Int { value }
                    public init(variable: Int) { self.variable = variable }
                }
                """
        )
    }

    func testClassFinal() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                final class Class {
                    var stored: Int
                    var computed: Int { 0 }
                }
                """,
            expected: """
                @available(swift 5.1)
                public final class Class {
                    public var stored: Int
                    public var computed: Int { 0 }
                }
                """
        )
    }

    func testClassNested() throws {
        try assertRule(
            defaultRule,
            source: """
                class Class {
                    class Nested {
                        var stored: Int
                    }
                }
                """,
            expected: """
                open class Class {
                    open class Nested {
                        public var stored: Int
                    }
                }
                """
        )
    }

    func testClassInternalNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal class Class {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """,
            expected: """
                internal class Class {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """
        )
    }

    func testClassOpenNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                open class Class {}
                """,
            expected: """
                open class Class {}
                """
        )
    }

    func testActor() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                actor Actor {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var stored: Int
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init(variable: Int) { self.variable = variable }
                }
                """,
            expected: """
                @available(swift 5.1)
                public actor Actor {
                    public typealias TypeAlias = Int
                    public static let staticStored = 0
                    public static func staticFunction() -> Int { 0 }
                    public var stored: Int
                    public var computed: Int { 0 }
                    internal var internalProperty: Int
                    public func function(value: Int) -> Int { value }
                    public subscript (value: Int) -> Int { value }
                    public init(variable: Int) { self.variable = variable }
                }
                """
        )
    }

    func testActorNested() throws {
        try assertRule(
            defaultRule,
            source: """
                actor Actor {
                    actor Nested {
                        var stored: Int
                    }
                }
                """,
            expected: """
                public actor Actor {
                    public actor Nested {
                        public var stored: Int
                    }
                }
                """
        )
    }

    func testActorNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal actor Actor {
                    actor Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """,
            expected: """
                internal actor Actor {
                    actor Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """
        )
    }

    func testEnum() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                enum Enum {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var computed: Int { 0 }
                    internal var internalComputed: Int { 0 }
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init() {}
                }
                """,
            expected: """
                @available(swift 5.1)
                public enum Enum {
                    public typealias TypeAlias = Int
                    public static let staticStored = 0
                    public static func staticFunction() -> Int { 0 }
                    public var computed: Int { 0 }
                    internal var internalComputed: Int { 0 }
                    public func function(value: Int) -> Int { value }
                    public subscript (value: Int) -> Int { value }
                    public init() {}
                }
                """
        )
    }

    func testEnumNested() throws {
        try assertRule(
            defaultRule,
            source: """
                enum Enum {
                    enum Nested {
                        case case1
                    }
                }
                """,
            expected: """
                public enum Enum {
                    public enum Nested {
                        case case1
                    }
                }
                """
        )
    }

    func testEnumNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal enum Enum {
                    enum Nested {
                        case case1
                    }
                }
                """,
            expected: """
                internal enum Enum {
                    enum Nested {
                        case case1
                    }
                }
                """
        )
    }

    func testProtocol() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                protocol Protocol {
                    associatedtype AssociatedType
                    static var staticStored: Int { get }
                    static func staticFunction() -> Int
                    var property: Int { get }
                    func function(value: Int) -> Int
                    subscript (value: Int) -> Int
                    init()
                }
                """,
            expected: """
                @available(swift 5.1)
                public protocol Protocol {
                    associatedtype AssociatedType
                    static var staticStored: Int { get }
                    static func staticFunction() -> Int
                    var property: Int { get }
                    func function(value: Int) -> Int
                    subscript (value: Int) -> Int
                    init()
                }
                """
        )
    }

    func testProtocolNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal protocol Protocol {}
                """,
            expected: """
                internal protocol Protocol {}
                """
        )
    }

    func testExtensionHasAccessLebel() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                extension Extension {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init() {}
                }
                """,
            expected: """
                @available(swift 5.1)
                extension Extension {
                    public typealias TypeAlias = Int
                    public static let staticStored = 0
                    public static func staticFunction() -> Int { 0 }
                    public var computed: Int { 0 }
                    internal var internalProperty: Int
                    public func function(value: Int) -> Int { value }
                    public subscript (value: Int) -> Int { value }
                    public init() {}
                }
                """
        )
    }

    func testExtensionHasNoAccessLebel() throws {
        try assertRule(
            defaultRule,
            source: """
                @available(swift 5.1)
                public extension Extension {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init() {}
                }
                """,
            expected: """
                @available(swift 5.1)
                public extension Extension {
                    typealias TypeAlias = Int
                    static let staticStored = 0
                    static func staticFunction() -> Int { 0 }
                    var computed: Int { 0 }
                    internal var internalProperty: Int
                    func function(value: Int) -> Int { value }
                    subscript (value: Int) -> Int { value }
                    init() {}
                }
                """
        )
    }

    func testExtensionNestedHasAccessLebel() throws {
        try assertRule(
            defaultRule,
            source: """
                extension Extension {
                    struct Struct {
                        var stored: Int
                    }
                    private struct PrivateStruct {
                        var stored: Int
                    }
                    class Class {
                        var stored: Int
                    }
                    enum Enum {
                        var computed: Int { 0 }
                    }
                }
                """,
            expected: """
                extension Extension {
                    public struct Struct {
                        public var stored: Int
                    }
                    private struct PrivateStruct {
                        var stored: Int
                    }
                    open class Class {
                        public var stored: Int
                    }
                    public enum Enum {
                        public var computed: Int { 0 }
                    }
                }
                """
        )
    }

    func testExtensionNestedHasNoAccessLebel() throws {
        try assertRule(
            defaultRule,
            source: """
                public extension Extension {
                    struct Struct {
                        var stored: Int
                    }
                    private struct PrivateStruct {
                        var stored: Int
                    }
                    class Class {
                        var stored: Int
                    }
                    enum Enum {
                        var computed: Int { 0 }
                    }
                }
                """,
            expected: """
                public extension Extension {
                    struct Struct {
                        public var stored: Int
                    }
                    private struct PrivateStruct {
                        var stored: Int
                    }
                    class Class {
                        public var stored: Int
                    }
                    enum Enum {
                        public var computed: Int { 0 }
                    }
                }
                """
        )
    }

    func testExtensionNotTriggered() throws {
        try assertRule(
            defaultRule,
            source: """
                internal extension Extension {
                    var property: Int { get }
                }
                """,
            expected: """
                internal extension Extension {
                    var property: Int { get }
                }
                """
        )
    }

    func testTopLevelVariable() throws {
        try assertRule(
            defaultRule,
            source: """
                let topLevelVariable = 0
                internal let internalTopLevelVariable = 0
                """,
            expected: """
                public let topLevelVariable = 0
                internal let internalTopLevelVariable = 0
                """
        )
    }

    func testTopLevelFuction() throws {
        try assertRule(
            defaultRule,
            source: """
                func topLevelFunction() {}
                internal func internalTopLevelFunction() {}
                """,
            expected: """
                public func topLevelFunction() {}
                internal func internalTopLevelFunction() {}
                """
        )
    }

    func testPrivate() throws {
        try assertRule(
            defaultRule,
            source: """
                private struct Struct {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """,
            expected: """
                private struct Struct {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """
        )
    }

    func testFilePrivate() throws {
        try assertRule(
            defaultRule,
            source: """
                fileprivate struct Struct {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """,
            expected: """
                fileprivate struct Struct {
                    class Nested {
                        var stored: Int
                    }
                    var stored: Int
                }
                """
        )
    }
}
