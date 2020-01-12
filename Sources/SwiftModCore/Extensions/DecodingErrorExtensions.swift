public extension DecodingError {
    var underlyingError: Error? {
        switch self {
        case .typeMismatch(_, let context):
            return context.underlyingError

        case .valueNotFound(_, let context):
            return context.underlyingError

        case .keyNotFound(_, let context):
            return context.underlyingError

        case .dataCorrupted(let context):
            return context.underlyingError

        @unknown default:
            return nil
        }
    }
}
