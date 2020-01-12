public struct RuleDescription {
    public var identifier: String
    public var priority: RulePriority
    public var overview: String
    public var exampleOptions: DynamicEncodable
    public var exampleBefore: String
    public var exampleAfter: String

    public init<Options: Encodable>(
        identifier: String,
        priority: RulePriority,
        overview: String,
        exampleOptions: Options,
        exampleBefore: String,
        exampleAfter: String
    ) {
        self.identifier = identifier
        self.priority = priority
        self.overview = overview
        self.exampleOptions = DynamicEncodable(encode: exampleOptions.encode)
        self.exampleBefore = exampleBefore
        self.exampleAfter = exampleAfter
    }
}
