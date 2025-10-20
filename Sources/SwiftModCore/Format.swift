public struct Format: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case indent
        case lineBreakBeforeEachArgument
    }

    public static let `default` = Format(indent: nil, lineBreakBeforeEachArgument: nil)

    private var underlyingIndent: Indent?
    private var underlyingLineBreakBeforeEachArgument: Bool?

    public var indent: Indent { underlyingIndent ?? .spaces(4) }
    public var lineBreakBeforeEachArgument: Bool { underlyingLineBreakBeforeEachArgument ?? true }

    public init(indent: Indent?, lineBreakBeforeEachArgument: Bool?) {
        self.underlyingIndent = indent
        self.underlyingLineBreakBeforeEachArgument = lineBreakBeforeEachArgument
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let indent = try container.decodeIfPresent(Indent.self, forKey: .indent)
        let lineBreakBeforeEachArgument = try container.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeEachArgument)

        self.init(
            indent: indent,
            lineBreakBeforeEachArgument: lineBreakBeforeEachArgument
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(underlyingIndent, forKey: .indent)
        try container.encodeIfPresent(underlyingLineBreakBeforeEachArgument, forKey: .lineBreakBeforeEachArgument)
    }
}
