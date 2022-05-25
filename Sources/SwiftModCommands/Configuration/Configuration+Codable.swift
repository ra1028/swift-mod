import SwiftModCore
import TSCBasic

extension Configuration: Codable {
    private enum CodingKeys: CodingKey {
        case format
        case rules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decodeIfPresent(Format.self, forKey: .format)
        let allRuleMap = Dictionary(
            uniqueKeysWithValues: Configuration.allRules.lazy.map { ($0.description.name, $0) }
        )

        try self.init(
            format: format,
            rules: container.decode([String: DecoderInterceptor].self, forKey: .rules).map { rule, interceptor in
                guard let ruleType = allRuleMap[rule] else {
                    throw ConfigurationError.invalidRuleName(rule)
                }

                do {
                    return try ruleType.init(from: interceptor.decoder, format: format ?? .default)
                }
                catch {
                    throw ConfigurationError.unexpectedRuleSetting(description: ruleType.description, error: error)
                }
            }
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(format, forKey: .format)
        var rulesContainer = container.nestedContainer(keyedBy: DynamicCondingKey.self, forKey: .rules)

        for rule in rules {
            let ruleEncodable = DynamicEncodable(encode: rule.encodeOptions)
            let key = DynamicCondingKey(type(of: rule).description.name)
            try rulesContainer.encode(ruleEncodable, forKey: key)
        }
    }
}
