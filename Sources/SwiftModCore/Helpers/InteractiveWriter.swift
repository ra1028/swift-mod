import TSCBasic

public protocol InteractiveWriterProtocol {
    func write(_ string: String, inColor color: TerminalController.Color, bold: Bool)
}

public extension InteractiveWriterProtocol {
    func write(_ string: String, inColor color: TerminalController.Color = .noColor, bold: Bool = false) {
        write(string, inColor: color, bold: bold)
    }
}

public final class InteractiveWriter: InteractiveWriterProtocol {
    public static let stdout = InteractiveWriter(stream: stdoutStream)
    public static let stderr = InteractiveWriter(stream: stderrStream)

    public let term: TerminalController?
    public let stream: OutputByteStream

    public init(stream: OutputByteStream) {
        self.term = TerminalController(stream: stream)
        self.stream = stream
    }

    public func write(_ string: String, inColor color: TerminalController.Color, bold: Bool) {
        if let term = term {
            term.write(string, inColor: color, bold: bold)
        }
        else {
            stream.send(string)
            stream.flush()
        }
    }
}

public final class InMemoryInteractiveWriter: InteractiveWriterProtocol {
    public struct Input: Equatable {
        public let string: String
        public let color: TerminalController.Color
        public let bold: Bool

        public init(
            string: String,
            color: TerminalController.Color,
            bold: Bool
        ) {
            self.string = string
            self.color = color
            self.bold = bold
        }
    }

    public var inputs = [Input]()

    public init() {}

    public func write(_ string: String, inColor color: TerminalController.Color, bold: Bool) {
        inputs.append(Input(string: string, color: color, bold: bold))
    }
}
