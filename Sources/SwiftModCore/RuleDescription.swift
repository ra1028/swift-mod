public struct RuleDescription: Sendable {
    public var name: String
    public var priority: RulePriority
    public var overview: String
    nonisolated(unsafe) public var exampleOptions: DynamicEncodable
    public var exampleBefore: String
    public var exampleAfter: String

    public init<Options: Sendable & Encodable>(
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
        self.exampleOptions = DynamicEncodable(
            encode: { encoder in
                try exampleOptions.encode(to: encoder)
            }
        )
        self.exampleBefore = exampleBefore
        self.exampleAfter = exampleAfter
    }
}
