import TSCBasic

public final class SwiftFileIterator: Sequence, IteratorProtocol {
    public static let fileExtension = "swift"

    public let referencePath: AbsolutePath
    public let paths: [AbsolutePath]
    public let excludedPaths: [AbsolutePath]?

    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol
    private var allPathIterator: Array<AbsolutePath>.Iterator
    private var directoryIterator: DirectoryEnumerable?
    private var globPathIterator: GlobPathIterator?

    public init(
        fileSystem: FileSystem,
        fileManager: FileManagerProtocol,
        referencePath: AbsolutePath,
        paths: [RelativePath],
        excludedPaths: [RelativePath]?
    ) {
        self.referencePath = referencePath
        self.paths = paths.map(referencePath.appending)
        self.excludedPaths = excludedPaths?.flatMap { path in
            GlobPathIterator(
                fileSystem: fileSystem,
                fileManager: fileManager,
                path: referencePath.appending(path)
            )
        }
        self.fileSystem = fileSystem
        self.fileManager = fileManager
        self.allPathIterator = self.paths.makeIterator()
    }

    public func next() -> AbsolutePath? {
        if let path = directoryIterator?.next() {
            return includedSwiftFilePath(path)
        }
        else if let path = globPathIterator?.next() {
            return includedSwiftFilePath(path)
        }
        else if let path = allPathIterator.next() {
            let isExcluded = excludedPaths?.contains(where: path.contains) ?? false

            if isExcluded {
                return next()
            }
            else if fileSystem.isDirectory(path) {
                directoryIterator = fileManager.enumerator(at: path)
                return next()
            }
            else if !fileSystem.exists(path) {
                globPathIterator = GlobPathIterator(fileSystem: fileSystem, fileManager: fileManager, path: path)
                return next()
            }
            else {
                return swiftFilePath(path)
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

    private func includedSwiftFilePath(_ path: AbsolutePath) -> AbsolutePath? {
        let isExcluded = excludedPaths?.contains(where: path.contains) ?? false

        guard !isExcluded else {
            return next()
        }

        return swiftFilePath(path)
    }
}
