import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var newTagName: String = ""
    @State private var newTagColor: Color = Theme.accentGreen
    @State private var newFavoriteName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                generalTab
                    .tabItem { Label("General", systemImage: "gearshape") }
                tagsTab
                    .tabItem { Label("Tags", systemImage: "tag") }
                favoritesTab
                    .tabItem { Label("Favorites", systemImage: "star") }
            }
        }
        .padding(20)
        .frame(width: 480, height: 440)
        .background(Theme.background2)
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Change History Storage")
                .font(.headline)
                .foregroundStyle(Theme.mainText)

            Text("Every rename, move, delete, tag, and comment change Warden makes is appended to this JSON file. A timestamped backup of it is made automatically every time Warden launches.")
                .font(.caption)
                .foregroundStyle(Theme.dimText)

            Text(settingsStore.settings.changeLogStoragePath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.mainText)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.background3)
                .clipShape(RoundedRectangle(cornerRadius: Theme.containerCornerRadius))
                .lineLimit(3)
                .truncationMode(.middle)

            Button("Choose Location…") {
                chooseChangeLogLocation()
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, 12)
    }

    private var tagsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags applied here are also written as real Finder tags, so they show up in Finder too.")
                .font(.caption)
                .foregroundStyle(Theme.dimText)

            List {
                ForEach(settingsStore.settings.tags) { tag in
                    HStack {
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: tag.colorHex) },
                            set: { settingsStore.updateTagColor(tag, to: $0.toHex()) }
                        ))
                        .labelsHidden()
                        Text(tag.name).foregroundStyle(Theme.mainText)
                        Spacer()
                        Button {
                            settingsStore.removeTag(tag)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.accentRed)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)

            HStack {
                TextField("New tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                ColorPicker("", selection: $newTagColor).labelsHidden()
                Button("Add") {
                    guard !newTagName.isEmpty else { return }
                    settingsStore.addTag(TagDefinition(name: newTagName, colorHex: newTagColor.toHex()))
                    newTagName = ""
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, 12)
    }

    private var favoritesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folders pinned here appear at the top of the sidebar.")
                .font(.caption)
                .foregroundStyle(Theme.dimText)

            List {
                ForEach(settingsStore.settings.favoriteLocations) { favorite in
                    HStack {
                        Text(favorite.name).foregroundStyle(Theme.mainText)
                        Spacer()
                        Text(favorite.path)
                            .font(.caption)
                            .foregroundStyle(Theme.faintText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button {
                            settingsStore.removeFavorite(favorite)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.accentRed)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)

            HStack {
                TextField("Name (optional)", text: $newFavoriteName)
                    .textFieldStyle(.roundedBorder)
                Button("Add Folder…") {
                    chooseFavoriteFolder()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, 12)
    }

    private func chooseChangeLogLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsOtherFileTypes = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose or create a JSON file to store the change history."
        panel.nameFieldStringValue = "change-history.json"
        if panel.runModal() == .OK, let url = panel.url {
            settingsStore.updateChangeLogPath(url.path)
        }
    }

    private func chooseFavoriteFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let name = newFavoriteName.isEmpty ? url.lastPathComponent : newFavoriteName
            settingsStore.addFavorite(FavoriteLocation(name: name, path: url.path))
            newFavoriteName = ""
        }
    }
}
