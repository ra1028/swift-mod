public struct CommandDescription<Options> {
    public var name: String
    public var usage: String
    public var overview: String
    public var defaultOptions: Options

    public init(
        name: String,
        usage: String,
        overview: String,
        defaultOptions: Options
    ) {
        self.name = name
        self.usage = usage
        self.overview = overview
        self.defaultOptions = defaultOptions
    }
}
