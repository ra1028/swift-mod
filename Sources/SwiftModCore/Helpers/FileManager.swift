import Foundation
import TSCBasic

public protocol FileManagerProtocol: AnyObject {
    @discardableResult
    func createFile(atPath path: String) -> Bool

    func enumerator(at path: AbsolutePath) -> DirectoryEnumerable?
}

extension FileManager: FileManagerProtocol {
    @discardableResult
    public func createFile(atPath path: String) -> Bool {
        createFile(atPath: path, contents: nil)
    }

    public func enumerator(at path: AbsolutePath) -> DirectoryEnumerable? {
        DirectoryIterator(rootPath: path)
    }
}

public final class InMemoryFileManager: FileManagerProtocol {
    public let fileSystem: InMemoryFileSystem

    public init(fileSystem: InMemoryFileSystem = InMemoryFileSystem()) {
        self.fileSystem = fileSystem
    }

    public func createFile(atPath path: String) -> Bool {
        do {
            try fileSystem.writeFileContents(AbsolutePath(validating: path), bytes: ByteString())
            return true
        }
        catch {
            return false
        }
    }

    public func enumerator(at path: AbsolutePath) -> DirectoryEnumerable? {
        final class InMemoryDirectoryIterator: DirectoryEnumerable {
            private var paths: [AbsolutePath]

            init(paths: [AbsolutePath] = []) {
                self.paths = paths
            }

            func next() -> AbsolutePath? {
                guard !paths.isEmpty else {
                    return nil
                }

                return paths.removeFirst()
            }
        }

        func getRecursiveDirectoryContents(rootPath: AbsolutePath) -> [AbsolutePath] {
            guard let contents = try? fileSystem.getDirectoryContents(rootPath) else {
                return []
            }

            return contents.sorted().flatMap { component -> [AbsolutePath] in
                let path = rootPath.appending(component: component)

                if fileSystem.isDirectory(path) {
                    return [path] + getRecursiveDirectoryContents(rootPath: path)
                }
                else {
                    return [path]
                }
            }
        }

        return InMemoryDirectoryIterator(paths: getRecursiveDirectoryContents(rootPath: path))
    }
}
