public extension String {
    init(_ any: Any) {
        self = "\(any)"
    }

    func offsetBeforeEachLines(_ offset: Int) -> String {
        let offsetString = String(repeating: " ", count: offset)
        return offsetString + replacingOccurrences(of: "\n", with: "\n\(offsetString)")
    }
}
