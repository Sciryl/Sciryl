import SwiftUI

struct FileRowView: View {
    let item: FileItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: IconProvider.symbolName(for: item))
                .foregroundStyle(IconProvider.color(for: item))
                .frame(width: 18)
            Text(item.name)
                .foregroundStyle(Theme.mainText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
