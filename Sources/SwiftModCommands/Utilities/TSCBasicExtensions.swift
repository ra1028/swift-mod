import TSCBasic
import ArgumentParser

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
