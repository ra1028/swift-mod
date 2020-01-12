import TSCBasic

public struct Target {
    public var paths: [RelativePath]
    public var excludedPaths: [RelativePath]?
    public var rules: [AnyRule]

    public init(
        paths: [RelativePath],
        excludedPaths: [RelativePath]?,
        rules: [AnyRule]
    ) {
        self.paths = paths
        self.excludedPaths = excludedPaths
        self.rules = rules
    }
}
