import TSCUtility

public protocol Command {
    associatedtype Options

    static var description: CommandDescription<Options> { get }

    func defineArguments(parser: ArgumentParser, binder: ArgumentBinder<Options>)
    func run(with options: Options) throws -> Int32
}
