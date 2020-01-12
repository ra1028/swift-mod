public struct Stack<Element> {
    private var buffer: ContiguousArray<Element>

    public var top: Element? {
        buffer.last
    }

    public init<S: Sequence>(_ buffer: S) where S.Element == Element {
        self.buffer = ContiguousArray(buffer)
    }

    public init() {
        self.init([])
    }

    public mutating func push(_ element: Element) {
        buffer.append(element)
    }

    @discardableResult
    public mutating func pop() -> Element? {
        buffer.popLast()
    }
}
