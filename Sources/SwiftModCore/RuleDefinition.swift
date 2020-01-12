import SwiftSyntax

public typealias RuleDefinition = Rule & RuleDefinable

public protocol RuleDefinable: AnyRule {
    associatedtype Options

    // Can't compile with `associatedtype Rewriter: RuleSyntaxRewriter<Options>`
    associatedtype Rewriter: RuleSyntaxRewriterProtocol where Rewriter.Options == Options
}

public extension RuleDefinable {
    init(
        isEnabled: Bool? = nil,
        options: Options,
        format: Format
    ) {
        self.init(
            isEnabled: isEnabled ?? true,
            makeRewriter: {
                Rewriter(
                    identifier: Self.description.identifier,
                    options: options,
                    format: format
                )
            },
            encodeOptions: { encoder in
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfPresent(isEnabled, forKey: .isEnabled)
                try options.encode(to: encoder)
            }
        )
    }

    init(from decoder: Decoder, format: Format) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
        let options = try Options(from: decoder)

        self.init(
            isEnabled: isEnabled,
            options: options,
            format: format
        )
    }
}

public protocol AnyRule: Rule {
    static var description: RuleDescription { get }

    init(from decoder: Decoder, format: Format) throws
}

open class Rule {
    public let isEnabled: Bool

    private let makeRewriter: () -> SyntaxRewriter
    private let encodeOptions: (Encoder) throws -> Void

    public required init(
        isEnabled: Bool = true,
        makeRewriter: @escaping () -> SyntaxRewriter,
        encodeOptions: @escaping (Encoder) throws -> Void
    ) {
        self.isEnabled = isEnabled
        self.makeRewriter = makeRewriter
        self.encodeOptions = encodeOptions
    }

    public final func rewriter() -> SyntaxRewriter {
        makeRewriter()
    }

    public final func encodeOptions(to encoder: Encoder) throws {
        try encodeOptions(encoder)
    }
}

private enum CodingKeys: String, CodingKey {
    case isEnabled = "enabled"
}
