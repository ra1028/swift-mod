import TSCBasic

public enum ConfigurationError: Error, CustomStringConvertible {
    case invalidSetting(error: Error)
    case invalidRuleName(String)
    case decodeFailed(error: Error)
    case loadFailed(path: AbsolutePath, error: Error)
    case unexpectedFormatSetting(details: String)
    case unexpectedRuleSetting(description: RuleDescription, error: Error)

    public var description: String {
        switch self {
        case .invalidSetting(let error):
            return """
                Configuration file has invalid setting.

                DETAILS:
                \(String(error).offsetBeforeEachLines(2))
                """

        case .invalidRuleName(let name):
            return "Configuration file contains an invalid rule '\(name)'"

        case .decodeFailed(let error):
            return """
                Could not decode configuration file.

                DETAILS:
                \(String(error).offsetBeforeEachLines(2))
                """

        case .loadFailed(let path, let error):
            return """
                Could not load configuration at '\(path.prettyPath())'.

                DETAILS:
                \(String(error).offsetBeforeEachLines(2))
                """

        case .unexpectedFormatSetting(let details):
            return """
                Unexpected format setting is found.

                DETAILS:
                \(details.offsetBeforeEachLines(2))
                """

        case .unexpectedRuleSetting(let description, let error):
            return """
                Unexpected rule setting is found in rule '\(description.name)'.

                DETAILS:
                \(String(error).offsetBeforeEachLines(2))
                """
        }
    }
}
