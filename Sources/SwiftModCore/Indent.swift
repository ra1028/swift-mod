public enum Indent: Codable, Equatable, Sendable {
    case spaces(Int)
    case tab

    private static let tabText = "tab"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let spaces = try? container.decode(Int.self) {
            self = .spaces(spaces)
        }
        else if let tab = try? container.decode(String.self), tab == Self.tabText {
            self = .tab
        }
        else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: """
                    The value for indent should specify number of spaces.
                    To use tab for indentation, specify tab by text.
                    """
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .spaces(let spaces):
            try container.encode(spaces)

        case .tab:
            try container.encode(Self.tabText)
        }
    }
}
