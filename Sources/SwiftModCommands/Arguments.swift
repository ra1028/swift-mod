import ArgumentParser
import TSCBasic

public enum Mode: String, CaseIterable, Sendable, ExpressibleByArgument {
    case modify
    case dryRun = "dry-run"
    case check
}

extension AbsolutePath: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        if let cwd = localFileSystem.currentWorkingDirectory {
            try? self.init(validating: argument, relativeTo: cwd)
        }
        else {
            try? self.init(validating: argument)
        }
    }
}
