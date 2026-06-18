import SwiftUI

struct CommentEditorView: View {
    let item: FileItem
    @Binding var draft: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment for \(item.name)")
                .font(.headline)
                .foregroundStyle(Theme.mainText)
                .lineLimit(1)
                .truncationMode(.middle)

            TextEditor(text: $draft)
                .frame(height: 120)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Theme.background3)
                .clipShape(RoundedRectangle(cornerRadius: Theme.containerCornerRadius))
                .foregroundStyle(Theme.mainText)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Save") {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(Theme.background2)
    }
}
