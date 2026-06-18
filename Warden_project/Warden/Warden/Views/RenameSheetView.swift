import SwiftUI

/// Single sheet that handles both single-item rename (Normal / Prefix /
/// Suffix) and multi-item rename (Sequential / Prefix / Suffix), per the
/// spec. Which modes are offered depends on how many items were selected.
struct RenameSheetView: View {
    let items: [FileItem]
    let onSubmit: (RenameOptions) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: RenameMode
    @State private var text: String
    @State private var separator: String = "_"
    @State private var startNumber: Int = 1
    @State private var padding: Int = 3

    init(items: [FileItem], onSubmit: @escaping (RenameOptions) -> Void) {
        self.items = items
        self.onSubmit = onSubmit
        let isMulti = items.count > 1
        _mode = State(initialValue: isMulti ? .sequential : .fullName)
        _text = State(initialValue: isMulti ? (items.first?.url.deletingPathExtension().lastPathComponent ?? "rename") : (items.first?.name ?? ""))
    }

    private var availableModes: [RenameMode] {
        items.count > 1 ? [.sequential, .prefix, .postfix] : [.fullName, .prefix, .postfix]
    }

    private var currentOptions: RenameOptions {
        RenameOptions(mode: mode, text: text, startNumber: startNumber, padding: padding, separator: separator)
    }

    private var preview: [(item: FileItem, newName: String)] {
        RenamePlanner.plan(for: items, options: currentOptions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(items.count > 1 ? "Rename \(items.count) Items" : "Rename")
                .font(.headline)
                .foregroundStyle(Theme.mainText)

            Picker("Mode", selection: $mode) {
                ForEach(availableModes) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: availableModes) { _, new in
                if !new.contains(mode), let first = new.first { mode = first }
            }

            optionsFields

            Divider().background(Theme.ruleColor)

            Text("Preview")
                .font(.caption)
                .foregroundStyle(Theme.dimText)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(preview, id: \.item.id) { entry in
                        HStack(spacing: 6) {
                            Text(entry.item.name)
                                .foregroundStyle(Theme.dimText)
                                .lineLimit(1)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Theme.faintText)
                            Text(entry.newName)
                                .foregroundStyle(Theme.accentGreen)
                                .lineLimit(1)
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .frame(maxHeight: 160)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Rename") {
                    onSubmit(currentOptions)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(text.isEmpty && mode != .fullName)
            }
        }
        .padding(20)
        .frame(width: 440)
        .background(Theme.background2)
    }

    @ViewBuilder
    private var optionsFields: some View {
        switch mode {
        case .fullName:
            TextField("New Name", text: $text)
                .textFieldStyle(.roundedBorder)
        case .prefix:
            TextField("Prefix Text", text: $text)
                .textFieldStyle(.roundedBorder)
            separatorField
        case .postfix:
            TextField("Suffix Text", text: $text)
                .textFieldStyle(.roundedBorder)
            separatorField
        case .sequential:
            TextField("Base Name", text: $text)
                .textFieldStyle(.roundedBorder)
            separatorField
            HStack(spacing: 16) {
                Stepper("Start at \(startNumber)", value: $startNumber, in: 1...9999)
                Stepper("Digits: \(padding)", value: $padding, in: 1...6)
            }
            .foregroundStyle(Theme.dimText)
        }
    }

    private var separatorField: some View {
        HStack {
            Text("Separator")
                .foregroundStyle(Theme.dimText)
            TextField("", text: $separator)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
        }
    }
}
