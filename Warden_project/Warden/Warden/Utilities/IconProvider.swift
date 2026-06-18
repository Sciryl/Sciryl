import SwiftUI

/// Every icon Warden shows comes from this one place. The app currently
/// uses SF Symbols so it needs no bundled image assets, but swapping any of
/// these for a custom icon set later only means editing this file.
struct IconProvider {
    static func symbolName(forLocationNamed name: String) -> String {
        switch name.lowercased() {
        case "desktop": return "menubar.dock.rectangle"
        case "documents": return "doc.on.doc"
        case "downloads": return "arrow.down.circle"
        case "home": return "house"
        case "dropbox": return "cloud"
        default: return "folder"
        }
    }

    static func symbolName(for item: FileItem) -> String {
        if item.isDirectory { return "folder.fill" }
        switch item.fileExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "heic", "tiff": return "photo"
        case "mov", "mp4", "m4v": return "film"
        case "mp3", "wav", "aac", "m4a": return "music.note"
        case "zip", "tar", "gz": return "archivebox"
        case "txt", "md", "rtf": return "doc.text"
        case "swift", "py", "js", "ts", "json", "html", "css": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }

    static func color(for item: FileItem) -> Color {
        item.isDirectory ? Theme.accentGreen : Theme.dimText
    }
}
