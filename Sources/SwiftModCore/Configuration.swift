public struct Configuration {
    public static let defaultFileName = ".swift-mod.yml"

    public var format: Format?
    public var rules: [AnyRule]

    public init(format: Format?, rules: [AnyRule]) {
        self.format = format
        self.rules = rules
    }
}
