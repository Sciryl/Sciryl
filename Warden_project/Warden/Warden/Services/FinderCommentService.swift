import Foundation
import AppKit

/// Reads and writes Finder comments.
///
/// Apple doesn't expose a Foundation/AppKit API for Finder comments, so the
/// only sanctioned way to touch them is to ask Finder itself to do it, via
/// an Apple Event (the same mechanism AppleScript uses). The first call will
/// prompt the user to allow Warden to control Finder — that's expected.
///
/// This requires `NSAppleEventsUsageDescription` in Info.plist (already set
/// via the project's INFOPLIST_KEY build setting) and, on a sandboxed build,
/// the `com.apple.security.automation.apple-events` entitlement. Warden
/// ships non-sandboxed, so no extra entitlement is required.
final class FinderCommentService {
    static let shared = FinderCommentService()

    func readComment(for url: URL) -> String? {
        let path = escapedPath(url)
        let script = """
        tell application "Finder"
            return comment of (POSIX file "\(path)" as alias)
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)
        guard errorInfo == nil else { return nil }
        return result.stringValue
    }

    @discardableResult
    func setComment(_ comment: String, for url: URL) -> Bool {
        let path = escapedPath(url)
        let escapedComment = comment
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Finder"
            set comment of (POSIX file "\(path)" as alias) to "\(escapedComment)"
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return false }
        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)
        return errorInfo == nil
    }

    private func escapedPath(_ url: URL) -> String {
        url.path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
