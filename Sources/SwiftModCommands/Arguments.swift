import ArgumentParser
import TSCBasic

public enum Mode: String, CaseIterable, ExpressibleByArgument {
    case modify
    case dryRun = "dry-run"
    case check
}

extension AbsolutePath: ExpressibleByArgument {
    public init?(argument: String) {
        if let cwd = localFileSystem.currentWorkingDirectory {
            self.init(argument, relativeTo: cwd)
        }
        else {
            try? self.init(validating: argument)
        }
    }
}
