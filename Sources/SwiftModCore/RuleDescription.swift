public struct RuleDescription {
    public var name: String
    public var priority: RulePriority
    public var overview: String
    public var exampleOptions: DynamicEncodable
    public var exampleBefore: String
    public var exampleAfter: String

    public init<Options: Encodable>(
        name: String,
        priority: RulePriority,
        overview: String,
        exampleOptions: Options,
        exampleBefore: String,
        exampleAfter: String
    ) {
        self.name = name
        self.priority = priority
        self.overview = overview
        self.exampleOptions = DynamicEncodable(encode: exampleOptions.encode)
        self.exampleBefore = exampleBefore
        self.exampleAfter = exampleAfter
    }
}
