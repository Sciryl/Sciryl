import SwiftUI

struct SidebarView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var browserVM: FileBrowserViewModel

    @State private var selection: URL?
    @State private var showingAddFavorite = false
    @State private var newFavoriteName: String = ""

    var body: some View {
        List(selection: $selection) {
            Section("Favorites") {
                ForEach(settingsStore.settings.favoriteLocations) { favorite in
                    Label(favorite.name, systemImage: IconProvider.symbolName(forLocationNamed: favorite.name))
                        .tag(favorite.url)
                        .contextMenu {
                            Button("Remove from Favorites", role: .destructive) {
                                settingsStore.removeFavorite(favorite)
                            }
                        }
                }
            }

            Section("Locations") {
                Label("Home", systemImage: "house")
                    .tag(FileManager.default.homeDirectoryForCurrentUser)
                Label("Desktop", systemImage: IconProvider.symbolName(forLocationNamed: "Desktop"))
                    .tag(desktopURL)
                Label("Documents", systemImage: IconProvider.symbolName(forLocationNamed: "Documents"))
                    .tag(documentsURL)
                Label("Dropbox", systemImage: IconProvider.symbolName(forLocationNamed: "Dropbox"))
                    .tag(dropboxURL)
            }

            if !mountedVolumes.isEmpty {
                Section("Volumes") {
                    ForEach(mountedVolumes, id: \.self) { volume in
                        Label(volume.lastPathComponent, systemImage: "externaldrive")
                            .tag(volume)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                newFavoriteName = browserVM.currentDirectory.lastPathComponent
                showingAddFavorite = true
            } label: {
                Label("Add Current Folder", systemImage: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(Theme.dimText)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .onChange(of: selection) { _, newValue in
            if let newValue { browserVM.navigate(to: newValue) }
        }
        .onChange(of: browserVM.currentDirectory) { _, newValue in
            selection = newValue
        }
        .alert("Add Favorite", isPresented: $showingAddFavorite) {
            TextField("Name", text: $newFavoriteName)
            Button("Add") {
                settingsStore.addFavorite(FavoriteLocation(name: newFavoriteName, path: browserVM.currentDirectory.path))
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var desktopURL: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? browserVM.currentDirectory
    }
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? browserVM.currentDirectory
    }
    private var dropboxURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Dropbox")
    }
    private var mountedVolumes: [URL] {
        FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
    }
}
