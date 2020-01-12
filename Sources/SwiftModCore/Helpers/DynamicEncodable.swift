public struct DynamicEncodable: Encodable {
    private var internalEncode: (Encoder) throws -> Void

    public init(encode: @escaping (Encoder) throws -> Void) {
        self.internalEncode = encode
    }

    public func encode(to encoder: Encoder) throws {
        try internalEncode(encoder)
    }
}
