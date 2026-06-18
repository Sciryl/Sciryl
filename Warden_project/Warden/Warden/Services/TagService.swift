import Foundation

/// Reads and writes Finder-compatible tags using the public
/// `URLResourceValues.tagNames` API. This is the same mechanism Finder
/// itself uses, so tags applied here show up in Finder and vice versa —
/// no private/system tag database access is needed or attempted.
final class TagService {
    static let shared = TagService()

    func currentTags(for url: URL) -> [String] {
        (try? url.resourceValues(forKeys: [.tagNamesKey]).tagNames) ?? []
    }

    func addTag(_ tagName: String, to url: URL) throws {
        var current = currentTags(for: url)
        guard !current.contains(tagName) else { return }
        current.append(tagName)
        try setTags(current, on: url)
    }

    func removeTag(_ tagName: String, from url: URL) throws {
        var current = currentTags(for: url)
        guard current.contains(tagName) else { return }
        current.removeAll { $0 == tagName }
        try setTags(current, on: url)
    }

    private func setTags(_ tags: [String], on url: URL) throws {
        var mutableURL = url
        var values = URLResourceValues()
        values.tagNames = tags
        try mutableURL.setResourceValues(values)
    }
}
