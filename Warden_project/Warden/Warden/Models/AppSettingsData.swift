import Foundation

/// Everything Warden persists about how it's configured: where the change
/// log lives, which folders are pinned, and which tags are available.
struct AppSettingsData: Codable, Equatable {
    var changeLogStoragePath: String
    var favoriteLocations: [FavoriteLocation]
    var tags: [TagDefinition]

    static func defaultSettings() -> AppSettingsData {
        let home = FileManager.default.homeDirectoryForCurrentUser

        let defaultFavorites = [
            FavoriteLocation(name: "Desktop", path: home.appendingPathComponent("Desktop").path),
            FavoriteLocation(name: "Documents", path: home.appendingPathComponent("Documents").path),
            FavoriteLocation(name: "Downloads", path: home.appendingPathComponent("Downloads").path),
            FavoriteLocation(name: "Home", path: home.path)
        ]

        let defaultTags = [
            TagDefinition(name: "Important", colorHex: "E14A3C"),
            TagDefinition(name: "In Progress", colorHex: "E87722"),
            TagDefinition(name: "Approved", colorHex: "A8D257"),
            TagDefinition(name: "Archive", colorHex: "C9CCC9")
        ]

        return AppSettingsData(
            changeLogStoragePath: AppPaths.defaultChangeLogURL.path,
            favoriteLocations: defaultFavorites,
            tags: defaultTags
        )
    }
}
