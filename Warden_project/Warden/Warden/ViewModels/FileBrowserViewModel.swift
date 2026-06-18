import Foundation
import Combine

/// Drives a single Finder-like browser pane: the current directory, the
/// loaded items, selection, search/filter/sort state, navigation history,
/// and every mutating action (rename, move, delete, tag, comment, create
/// folder). Every mutating action also writes a ChangeRecord and registers
/// an undo/redo step.
final class FileBrowserViewModel: ObservableObject {
    @Published var currentDirectory: URL
    @Published private(set) var items: [FileItem] = []
    @Published var selection: Set<URL> = []
    @Published var searchText: String = ""
    @Published var searchRecursive: Bool = false
    @Published var filterKind: FilterKind = .all
    @Published var sortOption: SortOption = .name
    @Published var sortAscending: Bool = true
    @Published var errorMessage: String?

    private var backStack: [URL] = []
    private var forwardStack: [URL] = []

    let fileSystem = FileSystemService.shared
    let tagService = TagService.shared
    let commentService = FinderCommentService.shared
    let changeTracker: ChangeTrackingService
    let settingsStore: SettingsStore

    enum FilterKind: String, CaseIterable, Identifiable {
        case all = "All"
        case foldersOnly = "Folders"
        case filesOnly = "Files"
        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case dateModified = "Date Modified"
        case size = "Size"
        var id: String { rawValue }
    }

    init(startDirectory: URL, changeTracker: ChangeTrackingService, settingsStore: SettingsStore) {
        self.currentDirectory = startDirectory
        self.changeTracker = changeTracker
        self.settingsStore = settingsStore
        load()
    }

    // MARK: Derived display list

    var displayedItems: [FileItem] {
        var result = items

        switch filterKind {
        case .all: break
        case .foldersOnly: result = result.filter(\.isDirectory)
        case .filesOnly: result = result.filter { !$0.isDirectory }
        }

        if !searchText.isEmpty, !searchRecursive {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        result.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory && !rhs.isDirectory }
            let ascending: Bool
            switch sortOption {
            case .name:
                ascending = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .dateModified:
                ascending = (lhs.modifiedDate ?? .distantPast) < (rhs.modifiedDate ?? .distantPast)
            case .size:
                ascending = (lhs.fileSize ?? 0) < (rhs.fileSize ?? 0)
            }
            return sortAscending ? ascending : !ascending
        }

        return result
    }

    // MARK: Loading & navigation

    func load() {
        if searchRecursive, !searchText.isEmpty {
            items = recursiveSearch(in: currentDirectory, matching: searchText)
        } else {
            items = fileSystem.contents(of: currentDirectory)
        }
    }

    private func recursiveSearch(in directory: URL, matching query: String) -> [FileItem] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .tagNamesKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var results: [FileItem] = []
        for case let url as URL in enumerator where url.lastPathComponent.localizedCaseInsensitiveContains(query) {
            results.append(FileItem(url: url))
        }
        return results
    }

    func navigate(to url: URL) {
        guard url != currentDirectory else { return }
        backStack.append(currentDirectory)
        forwardStack.removeAll()
        currentDirectory = url
        selection.removeAll()
        searchText = ""
        load()
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var canGoUp: Bool { currentDirectory.pathComponents.count > 1 }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentDirectory)
        currentDirectory = previous
        selection.removeAll()
        load()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentDirectory)
        currentDirectory = next
        selection.removeAll()
        load()
    }

    func goUp() {
        navigate(to: currentDirectory.deletingLastPathComponent())
    }

    // MARK: Create folder

    func createFolder(named name: String, undoManager: UndoManager?) {
        do {
            let newURL = try fileSystem.createFolder(named: name, in: currentDirectory)
            changeTracker.record(
                itemName: newURL.lastPathComponent, itemPath: newURL.path, itemType: "folder",
                action: .createFolder, attributeChanged: "existence",
                previousValue: "", newValue: newURL.path
            )
            registerUndoForCreate(at: newURL, undoManager: undoManager)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func registerUndoForCreate(at url: URL, undoManager: UndoManager?) {
        undoManager?.registerUndo(withTarget: self) { vm in
            try? FileManager.default.removeItem(at: url)
            vm.load()
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                vm2.createFolder(named: url.lastPathComponent, undoManager: undoManager)
            }
        }
        undoManager?.setActionName("Create Folder")
    }

    // MARK: Rename (single + multi, normal/prefix/postfix/sequential)

    func performRename(items renameItems: [FileItem], options: RenameOptions, undoManager: UndoManager?) {
        let plan = RenamePlanner.plan(for: renameItems, options: options)
        for (item, newName) in plan where !newName.isEmpty && newName != item.name {
            do {
                let destination = try fileSystem.rename(item: item, to: newName)
                changeTracker.record(
                    itemName: newName, itemPath: destination.path,
                    itemType: item.isDirectory ? "folder" : "file",
                    action: .rename, attributeChanged: "name",
                    previousValue: item.name, newValue: newName
                )
                registerUndoForRename(originalItem: item, newURL: destination, undoManager: undoManager)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        load()
    }

    private func registerUndoForRename(originalItem: FileItem, newURL: URL, undoManager: UndoManager?) {
        let oldName = originalItem.name
        let parent = originalItem.url.deletingLastPathComponent()

        undoManager?.registerUndo(withTarget: self) { vm in
            let currentItem = FileItem(url: newURL)
            _ = try? vm.fileSystem.rename(item: currentItem, to: oldName)
            vm.load()
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                let revertedItem = FileItem(url: parent.appendingPathComponent(oldName))
                _ = try? vm2.fileSystem.rename(item: revertedItem, to: newURL.lastPathComponent)
                vm2.load()
            }
        }
        undoManager?.setActionName("Rename")
    }

    // MARK: Delete (move to To Purge)

    func deleteSelected(undoManager: UndoManager?) {
        let toDelete = items.filter { selection.contains($0.url) }
        guard !toDelete.isEmpty else { return }

        do {
            let moved = try fileSystem.moveToPurgeFolder(toDelete)
            for entry in moved {
                changeTracker.record(
                    itemName: entry.item.name, itemPath: entry.newURL.path,
                    itemType: entry.item.isDirectory ? "folder" : "file",
                    action: .delete, attributeChanged: "location",
                    previousValue: entry.item.url.path, newValue: entry.newURL.path
                )
            }
            registerUndoForDelete(moved: moved, undoManager: undoManager)
            selection.removeAll()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func registerUndoForDelete(moved: [(item: FileItem, newURL: URL)], undoManager: UndoManager?) {
        guard !moved.isEmpty else { return }
        undoManager?.registerUndo(withTarget: self) { vm in
            for entry in moved {
                _ = try? vm.fileSystem.move(FileItem(url: entry.newURL), to: entry.item.url.deletingLastPathComponent())
            }
            vm.load()
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                let originals = moved.map(\.item)
                _ = try? vm2.fileSystem.moveToPurgeFolder(originals)
                vm2.load()
            }
        }
        undoManager?.setActionName("Move to To Purge")
    }

    // MARK: Move (drag & drop, or explicit "Move to…")

    func move(_ movedItems: [FileItem], to destination: URL, undoManager: UndoManager?) {
        var results: [(FileItem, URL)] = []
        for item in movedItems {
            do {
                let newURL = try fileSystem.move(item, to: destination)
                changeTracker.record(
                    itemName: item.name, itemPath: newURL.path,
                    itemType: item.isDirectory ? "folder" : "file",
                    action: .move, attributeChanged: "location",
                    previousValue: item.url.path, newValue: newURL.path
                )
                results.append((item, newURL))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        registerUndoForMove(results: results, undoManager: undoManager)
        load()
    }

    private func registerUndoForMove(results: [(FileItem, URL)], undoManager: UndoManager?) {
        guard !results.isEmpty else { return }
        undoManager?.registerUndo(withTarget: self) { vm in
            for (original, newURL) in results {
                _ = try? vm.fileSystem.move(FileItem(url: newURL), to: original.url.deletingLastPathComponent())
            }
            vm.load()
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                for (original, newURL) in results {
                    _ = try? vm2.fileSystem.move(original, to: newURL.deletingLastPathComponent())
                }
                vm2.load()
            }
        }
        undoManager?.setActionName("Move")
    }

    // MARK: Tags

    func toggleTag(_ tag: TagDefinition, for targetItems: [FileItem], undoManager: UndoManager?) {
        for item in targetItems {
            let current = tagService.currentTags(for: item.url)
            let wasPresent = current.contains(tag.name)
            do {
                if wasPresent {
                    try tagService.removeTag(tag.name, from: item.url)
                    changeTracker.record(
                        itemName: item.name, itemPath: item.url.path,
                        itemType: item.isDirectory ? "folder" : "file",
                        action: .tagRemoved, attributeChanged: "tag",
                        previousValue: tag.name, newValue: ""
                    )
                } else {
                    try tagService.addTag(tag.name, to: item.url)
                    changeTracker.record(
                        itemName: item.name, itemPath: item.url.path,
                        itemType: item.isDirectory ? "folder" : "file",
                        action: .tagAdded, attributeChanged: "tag",
                        previousValue: "", newValue: tag.name
                    )
                }
                registerUndoForTagToggle(tag: tag, item: item, wasAdded: !wasPresent, undoManager: undoManager)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        load()
    }

    private func registerUndoForTagToggle(tag: TagDefinition, item: FileItem, wasAdded: Bool, undoManager: UndoManager?) {
        undoManager?.registerUndo(withTarget: self) { vm in
            if wasAdded {
                try? vm.tagService.removeTag(tag.name, from: item.url)
            } else {
                try? vm.tagService.addTag(tag.name, to: item.url)
            }
            vm.load()
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                vm2.toggleTag(tag, for: [item], undoManager: undoManager)
            }
        }
        undoManager?.setActionName("Edit Tags")
    }

    // MARK: Comments

    func setComment(_ comment: String, for item: FileItem, undoManager: UndoManager?) {
        let previous = commentService.readComment(for: item.url) ?? ""
        guard commentService.setComment(comment, for: item.url) else {
            errorMessage = "Couldn't update the Finder comment for \(item.name). Warden may need permission to control Finder — check System Settings > Privacy & Security > Automation."
            return
        }
        changeTracker.record(
            itemName: item.name, itemPath: item.url.path,
            itemType: item.isDirectory ? "folder" : "file",
            action: .commentChanged, attributeChanged: "comment",
            previousValue: previous, newValue: comment
        )
        undoManager?.registerUndo(withTarget: self) { vm in
            _ = vm.commentService.setComment(previous, for: item.url)
            undoManager?.registerUndo(withTarget: vm) { vm2 in
                _ = vm2.commentService.setComment(comment, for: item.url)
            }
        }
        undoManager?.setActionName("Edit Comment")
    }
}
