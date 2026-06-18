import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @ObservedObject var browserVM: FileBrowserViewModel
    @Binding var showingNewFolderSheet: Bool
    @Binding var showingRenameSheet: Bool
    @Binding var showingCommentEditor: Bool
    @Binding var commentDraft: String
    @Binding var commentTarget: FileItem?

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Group {
            if browserVM.displayedItems.isEmpty {
                EmptyStateView(searchActive: !browserVM.searchText.isEmpty)
            } else {
                Table(browserVM.displayedItems, selection: $browserVM.selection) {
                    TableColumn("Name") { item in
                        FileRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                if item.isDirectory { browserVM.navigate(to: item.url) }
                            }
                            .contextMenu {
                                contextMenuContent(for: item)
                            }
                    }
                    .width(min: 220)

                    TableColumn("Tags") { item in
                        TagChipsView(tags: item.tags, settingsStore: browserVM.settingsStore)
                    }
                    .width(120)

                    TableColumn("Date Modified") { item in
                        Text(item.modifiedDate.map(DateFormatters.shortDateTime.string(from:)) ?? "—")
                            .foregroundStyle(Theme.dimText)
                    }
                    .width(150)

                    TableColumn("Size") { item in
                        Text(item.isDirectory ? "—" : DateFormatters.byteCount(item.fileSize))
                            .foregroundStyle(Theme.dimText)
                    }
                    .width(90)
                }
                .onDeleteCommand {
                    browserVM.deleteSelected(undoManager: undoManager)
                }
            }
        }
        .background(Theme.background)
        .searchable(text: $browserVM.searchText, placement: .toolbar, prompt: "Search this folder")
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers, into: browserVM.currentDirectory)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { browserVM.errorMessage != nil },
            set: { if !$0 { browserVM.errorMessage = nil } }
        )) {
            Button("OK") { browserVM.errorMessage = nil }
        } message: {
            Text(browserVM.errorMessage ?? "")
        }
    }

    /// Right-clicking an item that's part of a larger selection acts on the
    /// whole selection, matching Finder. Right-clicking an unselected item
    /// acts only on that item.
    private func targetItems(for item: FileItem) -> [FileItem] {
        if browserVM.selection.contains(item.url), browserVM.selection.count > 1 {
            return browserVM.displayedItems.filter { browserVM.selection.contains($0.url) }
        }
        return [item]
    }

    @ViewBuilder
    private func contextMenuContent(for item: FileItem) -> some View {
        let targets = targetItems(for: item)

        if targets.count == 1, targets[0].isDirectory {
            Button("Open") { browserVM.navigate(to: targets[0].url) }
        }

        Button(targets.count > 1 ? "Rename \(targets.count) Items…" : "Rename…") {
            browserVM.selection = Set(targets.map(\.url))
            showingRenameSheet = true
        }

        Button("Add Prefix…") {
            browserVM.selection = Set(targets.map(\.url))
            showingRenameSheet = true
        }

        Button("Add Suffix…") {
            browserVM.selection = Set(targets.map(\.url))
            showingRenameSheet = true
        }

        Menu("Tags") {
            ForEach(browserVM.settingsStore.settings.tags) { tag in
                Button {
                    browserVM.toggleTag(tag, for: targets, undoManager: undoManager)
                } label: {
                    Label(tag.name, systemImage: targets.allSatisfy { $0.tags.contains(tag.name) } ? "checkmark.circle.fill" : "circle")
                }
            }
        }

        if targets.count == 1 {
            Button("Edit Comment…") {
                let only = targets[0]
                commentTarget = only
                commentDraft = browserVM.commentService.readComment(for: only.url) ?? ""
                showingCommentEditor = true
            }
        }

        if !browserVM.settingsStore.settings.favoriteLocations.isEmpty {
            Menu("Move to…") {
                ForEach(browserVM.settingsStore.settings.favoriteLocations) { favorite in
                    Button(favorite.name) {
                        browserVM.move(targets, to: favorite.url, undoManager: undoManager)
                    }
                }
            }
        }

        Divider()

        Button("Move to To Purge", role: .destructive) {
            browserVM.selection = Set(targets.map(\.url))
            browserVM.deleteSelected(undoManager: undoManager)
        }
    }

    private func handleDrop(providers: [NSItemProvider], into destination: URL) -> Bool {
        var didHandle = false
        for provider in providers {
            didHandle = true
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    let item = FileItem(url: url)
                    browserVM.move([item], to: destination, undoManager: undoManager)
                }
            }
        }
        return didHandle
    }
}
