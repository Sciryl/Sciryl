import Foundation

/// The kind of action Warden performed on a file or folder.
/// Stored as a plain string in the change-history JSON so the file
/// stays human readable even outside the app.
enum ChangeAction: String, Codable, CaseIterable {
    case rename
    case move
    case delete
    case restore
    case createFolder
    case tagAdded
    case tagRemoved
    case commentChanged

    var displayName: String {
        switch self {
        case .rename: return "Rename"
        case .move: return "Move"
        case .delete: return "Move to To Purge"
        case .restore: return "Restore"
        case .createFolder: return "Create Folder"
        case .tagAdded: return "Tag Added"
        case .tagRemoved: return "Tag Removed"
        case .commentChanged: return "Comment Changed"
        }
    }
}
