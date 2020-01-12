import Foundation

public struct Measure {
    public var makeDate: () -> Date

    public init(_ makeDate: @escaping () -> Date = Date.init) {
        self.makeDate = makeDate
    }

    public func run<T>(_ action: () throws -> T) rethrows -> (value: T, time: TimeInterval) {
        let startTime = makeDate()
        let result = try action()
        let endTime = makeDate()
        let time = endTime.timeIntervalSince(startTime)
        return (result, time)
    }
}
