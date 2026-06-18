import SwiftUI

struct BrowserToolbarContent: ToolbarContent {
    @ObservedObject var browserVM: FileBrowserViewModel
    @Binding var showingSettings: Bool
    @Binding var showingHistory: Bool
    @Binding var showingNewFolderSheet: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { browserVM.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!browserVM.canGoBack)
            Button { browserVM.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!browserVM.canGoForward)
            Button { browserVM.goUp() } label: { Image(systemName: "chevron.up") }
                .disabled(!browserVM.canGoUp)
        }

        ToolbarItemGroup {
            Button { showingNewFolderSheet = true } label: { Image(systemName: "folder.badge.plus") }
                .help("New Folder")

            Menu {
                Picker("Show", selection: $browserVM.filterKind) {
                    ForEach(FileBrowserViewModel.FilterKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                Picker("Sort By", selection: $browserVM.sortOption) {
                    ForEach(FileBrowserViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle("Ascending", isOn: $browserVM.sortAscending)
                Toggle("Search Subfolders", isOn: $browserVM.searchRecursive)
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .help("Filter & Sort")

            Button { showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
                .help("Change History")

            Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                .help("Settings")
        }
    }
}
