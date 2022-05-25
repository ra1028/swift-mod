import Foundation
import TSCBasic

public protocol DirectoryEnumerable: AnyObject {
    func next() -> AbsolutePath?
}

public final class DirectoryIterator: DirectoryEnumerable, IteratorProtocol {
    private var rootPath: AbsolutePath?
    private let enumerator: FileManager.DirectoryEnumerator

    public init?(rootPath: AbsolutePath) {
        guard let enumerator = FileManager.default.enumerator(at: rootPath.asURL, includingPropertiesForKeys: [.pathKey], options: .skipsHiddenFiles) else {
            return nil
        }

        self.rootPath = rootPath
        self.enumerator = enumerator
    }

    public func next() -> AbsolutePath? {
        if let rootPath = rootPath {
            self.rootPath = nil
            return rootPath
        }

        guard let pathURL = enumerator.nextObject() as? URL else {
            return nil
        }

        return AbsolutePath(pathURL.path)
    }
}
