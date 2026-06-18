import Foundation

/// Centralizes every location Warden writes its own data to, so the rest of
/// the app never builds these paths by hand.
struct AppPaths {
    /// `~/Library/Application Support/Warden`
    static var applicationSupportFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let folder = base.appendingPathComponent("Warden", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// Where automatic backups of the change-history JSON are placed on launch.
    static var backupsFolder: URL {
        let folder = applicationSupportFolder.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// Default location for the change-history JSON until the user picks
    /// another one from Settings.
    static var defaultChangeLogURL: URL {
        applicationSupportFolder.appendingPathComponent("change-history.json")
    }

    /// Where Warden's own settings (tags, favorites, JSON path) are stored.
    static var settingsFileURL: URL {
        applicationSupportFolder.appendingPathComponent("settings.json")
    }

    /// `~/Desktop/To Purge` — where deleted items go instead of the system Trash.
    static var purgeFolderURL: URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        return desktop.appendingPathComponent("To Purge", isDirectory: true)
    }
}
