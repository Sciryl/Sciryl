import Foundation
import Combine

/// Owns the change-history JSON file: loading it, appending new records,
/// re-loading it whenever the user points Settings at a different file, and
/// backing it up automatically every time the app launches.
final class ChangeTrackingService: ObservableObject {
    @Published private(set) var records: [ChangeRecord] = []

    private let settingsStore: SettingsStore
    private var cancellable: AnyCancellable?
    private let fileManager = FileManager.default

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        loadRecords()

        cancellable = settingsStore.$settings
            .map(\.changeLogStoragePath)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadRecords()
            }
    }

    private var currentLogURL: URL {
        URL(fileURLWithPath: settingsStore.settings.changeLogStoragePath)
    }

    func loadRecords() {
        let url = currentLogURL
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder.wardenDecoder().decode([ChangeRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    /// Copies the *current* change-log JSON into the app's backups folder.
    /// Called once on every launch, before any new changes are recorded.
    func performLaunchBackup() {
        let url = currentLogURL
        guard fileManager.fileExists(atPath: url.path) else { return }

        let stamp = DateFormatters.backupStamp.string(from: Date())
        let backupURL = AppPaths.backupsFolder.appendingPathComponent("\(stamp)_backup.json")
        try? fileManager.copyItem(at: url, to: backupURL)
    }

    func record(itemName: String, itemPath: String, itemType: String, action: ChangeAction,
                attributeChanged: String, previousValue: String, newValue: String) {
        let entry = ChangeRecord(
            itemName: itemName, itemPath: itemPath, itemType: itemType, action: action,
            attributeChanged: attributeChanged, previousValue: previousValue,
            newValue: newValue, timestamp: Date()
        )
        records.append(entry)
        persist()
    }

    private func persist() {
        let url = currentLogURL
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder.wardenEncoder().encode(records) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
