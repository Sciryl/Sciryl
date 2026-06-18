import SwiftUI

struct NewFolderSheetView: View {
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "untitled folder"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Folder")
                .font(.headline)
                .foregroundStyle(Theme.mainText)

            TextField("Folder Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(create)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Create") { create() }
                    .buttonStyle(PrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Theme.background2)
    }

    private func create() {
        guard !name.isEmpty else { return }
        onCreate(name)
        dismiss()
    }
}
