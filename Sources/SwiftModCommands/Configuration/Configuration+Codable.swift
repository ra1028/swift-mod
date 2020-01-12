import SwiftModCore
import TSCBasic

extension Configuration: Codable {
    private enum CodingKeys: CodingKey {
        case format
        case targets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decodeIfPresent(Format.self, forKey: .format)

        try self.init(
            format: format,
            targets: container.decode([String: DecoderInterceptor].self, forKey: .targets).mapValues { interceptor in
                try Target(from: interceptor.decoder, format: format ?? .default)
            }
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encode(targets, forKey: .targets)
    }
}

extension Target: Encodable {
    public enum CodingKeys: CodingKey {
        case paths
        case excludedPaths
        case rules
    }

    public init(from decoder: Decoder, format: SwiftModCore.Format) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let allRuleMap = Dictionary(
            uniqueKeysWithValues: Configuration.allRules.lazy.map { ($0.description.identifier, $0) }
        )

        try self.init(
            paths: container.decode([RelativePath].self, forKey: .paths),
            excludedPaths: container.decodeIfPresent([RelativePath].self, forKey: .excludedPaths),
            rules: container.decode([String: DecoderInterceptor].self, forKey: .rules).map { identifier, interceptor in
                guard let ruleType = allRuleMap[identifier] else {
                    throw ConfigurationError.invalidRuleIdentifier(identifier)
                }

                do {
                    return try ruleType.init(from: interceptor.decoder, format: format)
                }
                catch {
                    throw ConfigurationError.unexpectedRuleSetting(description: ruleType.description, error: error)
                }
            }
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paths, forKey: .paths)
        try container.encodeIfPresent(excludedPaths, forKey: .excludedPaths)

        var rulesContainer = container.nestedContainer(keyedBy: DynamicCondingKey.self, forKey: .rules)

        for rule in rules {
            let ruleEncodable = DynamicEncodable(encode: rule.encodeOptions)
            let key = DynamicCondingKey(type(of: rule).description.identifier)
            try rulesContainer.encode(ruleEncodable, forKey: key)
        }
    }
}
