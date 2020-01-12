import Foundation
import TSCBasic
import TSCUtility

public final class Tool {
    private let parser: ArgumentParser
    private let binder = ArgumentBinder<CommandRunner>()
    private let mainCommand: CommandRunner
    private var commands = [String: CommandRunner]()

    public init<C: Command>(command: C) {
        let description = C.description
        parser = ArgumentParser(
            usage: description.usage,
            overview: description.overview
        )

        mainCommand = CommandRunner(command, parser: parser)
        add(command: command)
    }

    public func add<C: Command>(command: C) {
        let description = C.description
        let subparser = parser.add(
            subparser: description.name,
            usage: description.usage,
            overview: description.overview
        )

        commands[description.name] = CommandRunner(command, parser: subparser)
    }

    public func run(arguments: [String] = CommandLine.arguments) -> Int32 {
        let exitCode: Int32

        do {
            let commands = self.commands
            binder.bind(parser: parser) { selectedCommand, commandName in
                guard let command = commands[commandName] else { return }
                selectedCommand = command
            }

            let parseResult = try parser.parse(Array(arguments.dropFirst()))
            var selectedCommand = mainCommand
            try binder.fill(parseResult: parseResult, into: &selectedCommand)

            exitCode = try selectedCommand.run(parseResult)
        }
        catch {
            handle(error: error)
            exitCode = 1
        }

        return exitCode
    }
}

private extension Tool {
    func handle(error: Error) {
        switch error {
        case let anyError as AnyError:
            handle(error: anyError.underlyingError)

        case ArgumentParserError.expectedArguments(let parser, _):
            print(error: error)
            parser.printUsage(on: stderrStream)

        default:
            print(error: error)
        }
    }

    func print(error: Error) {
        let writer = InteractiveWriter.stderr
        writer.write("ERROR: ", inColor: .red, bold: true)
        writer.write("\(error)\n")
    }
}
