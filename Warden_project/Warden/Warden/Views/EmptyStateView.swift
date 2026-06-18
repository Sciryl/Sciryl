import SwiftUI

struct EmptyStateView: View {
    let searchActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: searchActive ? "magnifyingglass" : "folder")
                .font(.system(size: 40))
                .foregroundStyle(Theme.faintText)
            Text(searchActive ? "No matching items" : "This folder is empty")
                .foregroundStyle(Theme.dimText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}
