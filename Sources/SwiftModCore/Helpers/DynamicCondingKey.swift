public struct DynamicCondingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int? { nil }

    public init?(intValue: Int) { nil }

    public init?(stringValue: String) {
        self.init(stringValue)
    }

    public init(_ stringValue: String) {
        self.stringValue = stringValue
    }
}
