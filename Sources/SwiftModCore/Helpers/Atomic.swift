import Foundation

public final class Atomic<Value>: @unchecked Sendable {
    public var value: Value {
        get { modify { $0 } }
        set { modify { $0 = newValue } }
    }

    private let lock = NSLock()
    private var underlyingValue: Value

    public init(_ value: Value) {
        self.underlyingValue = value
    }

    @discardableResult
    public func withValue<T>(_ action: (Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try action(underlyingValue)
    }

    @discardableResult
    public func modify<T>(_ action: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try action(&underlyingValue)
    }
}
