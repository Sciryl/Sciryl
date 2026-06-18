# Warden

A Finder-like macOS file manager built with SwiftUI: browse, search, filter,
rename (single and batch), move, tag, comment, and organize files and
folders, with full change-history logging and undo/redo.

## Before your first build

1. Open `Warden.xcodeproj` in Xcode 16 or later.
2. Select the **Warden** target → **Signing & Capabilities**, and choose
   your own Team. Xcode may ask you to adjust `PRODUCT_BUNDLE_IDENTIFIER`
   (currently `com.warden.app`) if it collides with another app on your
   account — any unique reverse-DNS string works.
3. Build and run (⌘R). The default scheme is already set up.

## Known limitations / things to know

- **Untested code.** This was written and assembled without access to Xcode
  or a Swift compiler, so there's a real chance of small fixes needed once
  you build it for the first time (a typo, a missing import, etc.).
- **Not sandboxed.** App Sandbox is off so Warden can browse anywhere on
  disk, including outside its container. This means it should be
  distributed directly (Developer ID) rather than through the Mac App
  Store, and depending on what folders you browse, macOS may prompt for
  Full Disk Access in System Settings → Privacy & Security.
- **Dropbox is treated as a local folder** (`~/Dropbox`), not through
  Dropbox's API — there's no special sync-status awareness, just normal
  filesystem access to wherever your Dropbox folder lives.
- **Finder comments** are read/written via AppleScript (there's no other
  public API for this). The first time you edit a comment, macOS will
  prompt you to allow Warden to control Finder — this is expected. If
  it's denied, Warden shows an error rather than failing silently.
- **Custom fonts aren't embedded.** `Theme.swift` references "Barlow
  Condensed" and "JetBrains Mono" by name. If you don't add the actual
  font files to the project, SwiftUI silently falls back to the system
  font — nothing breaks, it just won't look exactly as specified until
  you add them.
- **Icons and buttons are centralized for easy re-skinning.** All icons
  come from `Utilities/IconProvider.swift` (currently SF Symbols), and all
  button appearances come from `Utilities/ButtonStyles.swift`. Swapping
  either later only means editing those two files.
- A `TagPickerView` component exists in `Views/` for a future
  popover-style multi-tag editor, but isn't wired to a trigger button yet
  — tagging currently works through the right-click "Tags" submenu.
- Deleted items move to `~/Desktop/To Purge` instead of the system Trash,
  per the spec — Warden never touches the real Trash.
