import Foundation

/// A folder the user has pinned to the sidebar for quick access.
struct FavoriteLocation: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var path: String

    var url: URL { URL(fileURLWithPath: path) }
}
