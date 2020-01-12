import TSCBasic

public final class InteractiveWriter {
    public static let stdout = InteractiveWriter(stream: stdoutStream)
    public static let stderr = InteractiveWriter(stream: stderrStream)

    public let term: TerminalController?
    public let stream: OutputByteStream

    public init(stream: OutputByteStream) {
        self.term = TerminalController(stream: stream)
        self.stream = stream
    }

    public func write(_ string: String, inColor color: TerminalController.Color = .noColor, bold: Bool = false) {
        if let term = term {
            term.write(string, inColor: color, bold: bold)
        }
        else {
            stream <<< string
            stream.flush()
        }
    }
}
