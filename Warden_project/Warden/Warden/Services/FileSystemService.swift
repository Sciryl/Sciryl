import Foundation

enum FileOperationError: LocalizedError {
    case destinationExists(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .destinationExists(let name):
            return "An item named \"\(name)\" already exists at the destination."
        case .operationFailed(let message):
            return message
        }
    }
}

/// Wraps every read/write filesystem operation Warden performs. Kept
/// deliberately free of UI and change-tracking concerns so it stays simple
/// to reason about: it only ever touches the disk and returns results.
final class FileSystemService {
    static let shared = FileSystemService()
    private let fileManager = FileManager.default

    func contents(of directory: URL, includeHidden: Bool = false) -> [FileItem] {
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .fileSizeKey, .contentModificationDateKey,
            .creationDateKey, .tagNamesKey, .isHiddenKey
        ]
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !includeHidden { options.insert(.skipsHiddenFiles) }

        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys, options: options
        ) else {
            return []
        }

        return urls.map(FileItem.init).sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory && !rhs.isDirectory }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    @discardableResult
    func createFolder(named name: String, in directory: URL) throws -> URL {
        let target = uniqueURL(for: directory.appendingPathComponent(name, isDirectory: true))
        try fileManager.createDirectory(at: target, withIntermediateDirectories: false)
        return target
    }

    /// Renames a single item in place (same parent folder).
    @discardableResult
    func rename(item: FileItem, to newName: String) throws -> URL {
        let destination = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        guard destination.path != item.url.path else { return item.url }
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw FileOperationError.destinationExists(newName)
        }
        try fileManager.moveItem(at: item.url, to: destination)
        return destination
    }

    /// Moves a single item into a different folder, resolving name
    /// collisions automatically (e.g. "report.pdf" -> "report 2.pdf").
    @discardableResult
    func move(_ item: FileItem, to destinationFolder: URL) throws -> URL {
        let proposed = destinationFolder.appendingPathComponent(item.name)
        let destination = uniqueURL(for: proposed)
        try fileManager.moveItem(at: item.url, to: destination)
        return destination
    }

    /// Moves items to ~/Desktop/To Purge instead of the system Trash, per
    /// the app's non-destructive delete behavior.
    func moveToPurgeFolder(_ items: [FileItem]) throws -> [(item: FileItem, newURL: URL)] {
        let purgeFolder = AppPaths.purgeFolderURL
        if !fileManager.fileExists(atPath: purgeFolder.path) {
            try fileManager.createDirectory(at: purgeFolder, withIntermediateDirectories: true)
        }

        var results: [(FileItem, URL)] = []
        for item in items {
            let proposed = purgeFolder.appendingPathComponent(item.name)
            let destination = uniqueURL(for: proposed)
            try fileManager.moveItem(at: item.url, to: destination)
            results.append((item, destination))
        }
        return results
    }

    /// Appends " 2", " 3", etc. until the URL no longer collides with an
    /// existing item. Used by every move/create/purge operation so nothing
    /// ever silently overwrites existing data.
    func uniqueURL(for url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }

        let ext = url.pathExtension
        let base = ext.isEmpty ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
        let folder = url.deletingLastPathComponent()

        var counter = 2
        var candidate = url
        while fileManager.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = folder.appendingPathComponent(newName)
            counter += 1
        }
        return candidate
    }
}
