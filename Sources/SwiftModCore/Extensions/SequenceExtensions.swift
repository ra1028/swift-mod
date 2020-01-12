public extension Sequence {
    var first: Element? {
        first { _ in true }
    }
}
