import Foundation
import SwiftModCore
import TSCBasic
import TSCUtility

func parseOptions<C: Command>(_ command: C, arguments: [String]) throws -> C.Options {
    let parser = ArgumentParser(commandName: "", usage: "", overview: "")
    let binder = ArgumentBinder<C.Options>()
    command.defineArguments(parser: parser, binder: binder)
    let parseResult = try parser.parse(arguments)
    var options = C.description.defaultOptions
    try binder.fill(parseResult: parseResult, into: &options)
    return options
}
