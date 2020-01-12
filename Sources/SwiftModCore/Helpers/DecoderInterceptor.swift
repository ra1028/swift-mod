public struct DecoderInterceptor: Decodable {
    public let decoder: Decoder

    public init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}
