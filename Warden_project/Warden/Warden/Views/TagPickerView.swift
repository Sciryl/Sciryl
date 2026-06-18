import SwiftUI

/// Small colored dots shown in the Tags column — a quick-glance summary
/// rather than full tag names, matching Finder's own tag dot convention.
struct TagChipsView: View {
    let tags: [String]
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(3), id: \.self) { tagName in
                Circle()
                    .fill(colorFor(tagName))
                    .frame(width: 8, height: 8)
            }
            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(Theme.faintText)
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        if let match = settingsStore.settings.tags.first(where: { $0.name == name }) {
            return Color(hex: match.colorHex)
        }
        return Theme.silver
    }
}

/// A small popover-style picker for toggling the app's known tags on the
/// current selection.
struct TagPickerView: View {
    let items: [FileItem]
    @ObservedObject var settingsStore: SettingsStore
    let onToggle: (TagDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(Theme.mainText)

            if settingsStore.settings.tags.isEmpty {
                Text("No tags yet. Add some from Settings.")
                    .font(.caption)
                    .foregroundStyle(Theme.dimText)
            }

            ForEach(settingsStore.settings.tags) { tag in
                Button {
                    onToggle(tag)
                } label: {
                    HStack {
                        Circle().fill(Color(hex: tag.colorHex)).frame(width: 10, height: 10)
                        Text(tag.name).foregroundStyle(Theme.mainText)
                        Spacer()
                        if items.allSatisfy({ $0.tags.contains(tag.name) }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accentGreen)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Divider().background(Theme.ruleColor)
            Button("Done") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(16)
        .frame(width: 240)
        .background(Theme.background2)
    }
}
