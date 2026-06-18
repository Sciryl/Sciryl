import Foundation

/// An app-managed tag definition: a name plus a custom display color.
/// Applying a tag to a file also writes a Finder-compatible tag (via
/// `URLResourceValues.tagNames`) so the tag shows up in Finder too.
struct TagDefinition: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
}
