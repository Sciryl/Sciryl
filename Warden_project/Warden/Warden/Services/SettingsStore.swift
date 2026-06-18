import Foundation
import Combine

/// Owns Warden's persisted settings (change-log location, tags, favorite
/// folders) and writes them to `~/Library/Application Support/Warden/settings.json`
/// on every change. Views observe `settings` directly; nothing else in the
/// app talks to the settings file.
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettingsData {
        didSet { persist() }
    }

    init() {
        if let data = try? Data(contentsOf: AppPaths.settingsFileURL),
           let decoded = try? JSONDecoder.wardenDecoder().decode(AppSettingsData.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettingsData.defaultSettings()
        }
    }

    func updateChangeLogPath(_ newPath: String) {
        settings.changeLogStoragePath = newPath
    }

    func addFavorite(_ favorite: FavoriteLocation) {
        guard !settings.favoriteLocations.contains(where: { $0.path == favorite.path }) else { return }
        settings.favoriteLocations.append(favorite)
    }

    func removeFavorite(_ favorite: FavoriteLocation) {
        settings.favoriteLocations.removeAll { $0.id == favorite.id }
    }

    func addTag(_ tag: TagDefinition) {
        guard !settings.tags.contains(where: { $0.name.caseInsensitiveCompare(tag.name) == .orderedSame }) else { return }
        settings.tags.append(tag)
    }

    func removeTag(_ tag: TagDefinition) {
        settings.tags.removeAll { $0.id == tag.id }
    }

    func updateTagColor(_ tag: TagDefinition, to newColorHex: String) {
        guard let index = settings.tags.firstIndex(where: { $0.id == tag.id }) else { return }
        settings.tags[index].colorHex = newColorHex
    }

    private func persist() {
        guard let data = try? JSONEncoder.wardenEncoder().encode(settings) else { return }
        try? data.write(to: AppPaths.settingsFileURL, options: .atomic)
    }
}
