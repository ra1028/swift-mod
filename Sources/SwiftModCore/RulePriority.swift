public struct RulePriority: RawRepresentable, Comparable, Sendable {
    public var rawValue: Int

    public static let high = RulePriority(rawValue: 1000)
    public static let `default` = RulePriority(rawValue: 750)
    public static let low = RulePriority(rawValue: 500)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static func < (lhs: RulePriority, rhs: RulePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
