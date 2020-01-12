import Foundation
import TSCBasic

public final class GlobPathIterator: Sequence, IteratorProtocol {
    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol
    private var path: AbsolutePath?
    private var recursiveIterator: RecursiveGlobPathIterator?

    public init(fileSystem: FileSystem, fileManager: FileManagerProtocol, path: AbsolutePath) {
        self.fileSystem = fileSystem
        self.fileManager = fileManager
        self.path = path
    }

    public func next() -> AbsolutePath? {
        if let path = recursiveIterator?.next() {
            return path
        }
        else if let path = path {
            self.path = nil
            return resolved(path: path)
        }
        else {
            return nil
        }
    }

    private func resolved(path: AbsolutePath) -> AbsolutePath? {
        if let globPath = path.globPathSeparatingAtFirst() {
            recursiveIterator = RecursiveGlobPathIterator(
                fileSystem: fileSystem,
                fileManager: fileManager,
                leadingPath: globPath.leading,
                trailingPath: globPath.trailing
            )
            return next()
        }
        else {
            return path
        }
    }
}

private final class RecursiveGlobPathIterator: IteratorProtocol {
    let leadingPath: AbsolutePath
    let trailingPath: RelativePath
    private let fileSystem: FileSystem
    private let fileManager: FileManagerProtocol
    private let directoryIterator: DirectoryEnumerable?
    private var recursiveIterator: RecursiveGlobPathIterator?
    private var globIterator: GlobIterator?

    public init(
        fileSystem: FileSystem,
        fileManager: FileManagerProtocol,
        leadingPath: AbsolutePath,
        trailingPath: RelativePath
    ) {
        self.fileSystem = fileSystem
        self.fileManager = fileManager
        self.leadingPath = leadingPath
        self.trailingPath = trailingPath
        self.directoryIterator = fileManager.enumerator(at: leadingPath)
    }

    func next() -> AbsolutePath? {
        if let path = recursiveIterator?.next() {
            return path
        }
        else if let path = globIterator?.next() {
            return path
        }
        else if let path = directoryIterator?.next() {
            return resolved(path: path)
        }
        else {
            return nil
        }
    }

    private func resolved(path: AbsolutePath) -> AbsolutePath? {
        if !fileSystem.isDirectory(path) {
            return next()
        }
        else if let globPath = trailingPath.globPathSeparatingAtFirst() {
            recursiveIterator = RecursiveGlobPathIterator(
                fileSystem: fileSystem,
                fileManager: fileManager,
                leadingPath: path.appending(globPath.leading),
                trailingPath: globPath.trailing
            )
            return next()
        }
        else if let globIterator = GlobIterator(path: path.appending(trailingPath)) {
            self.globIterator = globIterator
            return next()
        }
        else {
            return next()
        }
    }
}

private final class GlobIterator: IteratorProtocol {
    let path: AbsolutePath
    private let count: Int
    private var gt = glob_t()
    private var position = 0

    deinit {
        globfree(&gt)
    }

    init?(path: AbsolutePath) {
        guard glob(path.pathString, GLOB_TILDE | GLOB_BRACE | GLOB_MARK, nil, &gt) == 0 else {
            return nil
        }

        self.path = path
        #if os(Linux)
            count = Int(gt.gl_pathc)
        #else
            count = Int(gt.gl_matchc)
        #endif
    }

    func next() -> AbsolutePath? {
        guard position < count,
            let pathPointer = gt.gl_pathv[position],
            let path = String(validatingUTF8: pathPointer)
        else {
            return nil
        }

        defer { position += 1 }

        return AbsolutePath(path)
    }
}

private let globstar = "**"

private extension AbsolutePath {
    func globPathSeparatingAtFirst() -> (leading: AbsolutePath, trailing: RelativePath)? {
        guard pathString.contains(globstar) else {
            return nil
        }

        let components = pathString.components(separatedBy: globstar)
        let leading = AbsolutePath(components.first!)
        let trailing = RelativePath(trimming: components.lazy.dropFirst().joined(separator: globstar))
        return (leading, trailing)
    }
}

private extension RelativePath {
    init(trimming path: String) {
        switch path.first {
        case "/":
            self.init(String(path.dropFirst()))

        default:
            self.init(path)
        }
    }

    func globPathSeparatingAtFirst() -> (leading: RelativePath, trailing: RelativePath)? {
        guard pathString.contains(globstar) else {
            return nil
        }

        let components = pathString.components(separatedBy: globstar)
        let leading = RelativePath(components.first!)
        let trailing = RelativePath(trimming: components.lazy.dropFirst().joined(separator: globstar))
        return (leading, trailing)
    }
}
