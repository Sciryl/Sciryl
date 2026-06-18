import Foundation

/// A lightweight, display-ready snapshot of a file or folder on disk.
/// Re-created on every directory load rather than mutated in place, so the
/// browser always reflects the real filesystem state.
struct FileItem: Identifiable, Hashable {
    let url: URL
    var name: String
    var isDirectory: Bool
    var fileSize: Int64?
    var modifiedDate: Date?
    var createdDate: Date?
    var tags: [String]
    /// Finder comments are loaded on demand (see FinderCommentService) rather
    /// than eagerly for every row, since reading them requires an Apple
    /// Event round-trip to Finder.
    var comment: String?

    var id: URL { url }

    var fileExtension: String { url.pathExtension }

    init(url: URL) {
        self.url = url
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey, .fileSizeKey, .contentModificationDateKey,
            .creationDateKey, .tagNamesKey
        ])
        self.name = url.lastPathComponent
        self.isDirectory = values?.isDirectory ?? false
        self.fileSize = values?.fileSize.map(Int64.init)
        self.modifiedDate = values?.contentModificationDate
        self.createdDate = values?.creationDate
        self.tags = values?.tagNames ?? []
        self.comment = nil
    }
}
