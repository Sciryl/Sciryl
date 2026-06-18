import Foundation

/// A single entry in Warden's change-history log.
/// Every mutating action the app performs is recorded as one of these and
/// appended to the JSON file the user configured in Settings.
struct ChangeRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var itemName: String
    var itemPath: String
    var itemType: String          // "file" or "folder"
    var action: ChangeAction
    var attributeChanged: String  // e.g. "name", "tag", "comment", "location"
    var previousValue: String
    var newValue: String
    var timestamp: Date
}
