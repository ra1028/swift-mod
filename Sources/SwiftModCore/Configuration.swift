public struct Configuration {
    public static let defaultFileName = ".swift-mod.yml"

    public var format: Format?
    public var targets: [String: Target]

    public init(format: Format?, targets: [String: Target]) {
        self.format = format
        self.targets = targets
    }
}
