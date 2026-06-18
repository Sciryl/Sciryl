import Foundation

/// Which renaming behavior is active in the rename sheet. Single selection
/// offers .fullName; multi-selection offers .sequential. Prefix/postfix
/// work for both, per the spec.
enum RenameMode: String, CaseIterable, Identifiable {
    case fullName = "New Name"
    case prefix = "Add Prefix"
    case postfix = "Add Suffix"
    case sequential = "Sequential"

    var id: String { rawValue }
}

struct RenameOptions {
    var mode: RenameMode
    var text: String = ""
    var startNumber: Int = 1
    var padding: Int = 3
    var separator: String = "_"
}

/// Pure, side-effect-free naming logic shared by the rename sheet's live
/// preview and the view model's actual rename execution, so the preview the
/// user sees always matches what happens when they hit Rename.
struct RenamePlanner {
    static func plan(for items: [FileItem], options: RenameOptions) -> [(item: FileItem, newName: String)] {
        guard !options.text.isEmpty || options.mode == .fullName else { return [] }

        switch options.mode {
        case .fullName:
            guard let first = items.first else { return [] }
            return [(first, options.text)]

        case .prefix:
            return items.map { item in
                (item, "\(options.text)\(options.separator)\(item.name)")
            }

        case .postfix:
            return items.map { item in
                let (base, ext) = splitName(item)
                let newBase = "\(base)\(options.separator)\(options.text)"
                return (item, ext.isEmpty ? newBase : "\(newBase).\(ext)")
            }

        case .sequential:
            return items.enumerated().map { index, item in
                let number = options.startNumber + index
                let numberString = String(format: "%0\(max(options.padding, 1))d", number)
                let (_, ext) = splitName(item)
                let newBase = "\(options.text)\(options.separator)\(numberString)"
                return (item, ext.isEmpty ? newBase : "\(newBase).\(ext)")
            }
        }
    }

    /// Splits a name into base + extension, treating folders as having no
    /// extension even if their name happens to contain a dot.
    private static func splitName(_ item: FileItem) -> (base: String, ext: String) {
        if item.isDirectory {
            return (item.name, "")
        }
        let url = item.url
        let ext = url.pathExtension
        let base = ext.isEmpty ? item.name : url.deletingPathExtension().lastPathComponent
        return (base, ext)
    }
}
