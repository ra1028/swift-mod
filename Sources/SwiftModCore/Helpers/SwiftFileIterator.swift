import TSCBasic

public final class SwiftFileIterator: Sequence, IteratorProtocol {
    public static let fileExtension = "swift"

    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol
    private var pathIterator: Array<AbsolutePath>.Iterator
    private var directoryIterator: DirectoryEnumerable?

    public init(
        fileSystem: FileSystem,
        fileManager: FileManagerProtocol,
        paths: [AbsolutePath]
    ) {
        self.fileSystem = fileSystem
        self.fileManager = fileManager
        self.pathIterator = paths.makeIterator()
    }

    public func next() -> AbsolutePath? {
        if let path = directoryIterator?.next() {
            return swiftFilePath(path)
        }
        else if let path = pathIterator.next() {
            if fileSystem.isDirectory(path) {
                directoryIterator = fileManager.enumerator(at: path)
                return next()
            }
            else if fileSystem.exists(path) {
                return swiftFilePath(path)
            }
            else {
                return next()
            }
        }
        else {
            return nil
        }
    }

    private func swiftFilePath(_ path: AbsolutePath) -> AbsolutePath? {
        guard fileSystem.isFile(path) && path.extension == Self.fileExtension else {
            return next()
        }

        return path
    }
}
