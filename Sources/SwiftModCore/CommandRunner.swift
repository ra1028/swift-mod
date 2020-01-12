import TSCUtility

public struct CommandRunner {
    public let run: (ArgumentParser.Result) throws -> Int32

    public init<C: Command>(_ command: C, parser: ArgumentParser) {
        let binder = ArgumentBinder<C.Options>()
        command.defineArguments(parser: parser, binder: binder)

        run = { parseResult in
            var options = C.description.defaultOptions
            try binder.fill(parseResult: parseResult, into: &options)
            return try command.run(with: options)
        }
    }
}
