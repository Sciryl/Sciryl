import SwiftUI

struct ContentView: View {
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var changeTracker: ChangeTrackingService
    @StateObject private var browserVM: FileBrowserViewModel

    @Environment(\.undoManager) private var undoManager

    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingNewFolderSheet = false
    @State private var showingRenameSheet = false
    @State private var showingCommentEditor = false
    @State private var commentDraft: String = ""
    @State private var commentTarget: FileItem?

    init() {
        let settings = SettingsStore()
        let tracker = ChangeTrackingService(settingsStore: settings)
        let start = FileManager.default.homeDirectoryForCurrentUser
        _settingsStore = StateObject(wrappedValue: settings)
        _changeTracker = StateObject(wrappedValue: tracker)
        _browserVM = StateObject(wrappedValue: FileBrowserViewModel(
            startDirectory: start, changeTracker: tracker, settingsStore: settings
        ))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(settingsStore: settingsStore, browserVM: browserVM)
        } detail: {
            FileListView(
                browserVM: browserVM,
                showingNewFolderSheet: $showingNewFolderSheet,
                showingRenameSheet: $showingRenameSheet,
                showingCommentEditor: $showingCommentEditor,
                commentDraft: $commentDraft,
                commentTarget: $commentTarget
            )
            .navigationTitle(browserVM.currentDirectory.lastPathComponent)
        }
        .toolbar {
            BrowserToolbarContent(
                browserVM: browserVM,
                showingSettings: $showingSettings,
                showingHistory: $showingHistory,
                showingNewFolderSheet: $showingNewFolderSheet
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsStore: settingsStore)
        }
        .sheet(isPresented: $showingHistory) {
            ChangeHistoryView(changeTracker: changeTracker)
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheetView { name in
                browserVM.createFolder(named: name, undoManager: undoManager)
            }
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameSheetView(items: browserVM.displayedItems.filter { browserVM.selection.contains($0.url) }) { options in
                let targets = browserVM.displayedItems.filter { browserVM.selection.contains($0.url) }
                browserVM.performRename(items: targets, options: options, undoManager: undoManager)
            }
        }
        .sheet(isPresented: $showingCommentEditor) {
            if let target = commentTarget {
                CommentEditorView(item: target, draft: $commentDraft) { newComment in
                    browserVM.setComment(newComment, for: target, undoManager: undoManager)
                }
            }
        }
        .onAppear {
            changeTracker.performLaunchBackup()
        }
        .preferredColorScheme(.dark)
        .frame(minWidth: 900, minHeight: 600)
    }
}
