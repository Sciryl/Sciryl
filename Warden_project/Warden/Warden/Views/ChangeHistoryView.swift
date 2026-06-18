import SwiftUI

struct ChangeHistoryView: View {
    @ObservedObject var changeTracker: ChangeTrackingService
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var filtered: [ChangeRecord] {
        let sorted = changeTracker.records.sorted { $0.timestamp > $1.timestamp }
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.itemName.localizedCaseInsensitiveContains(query) ||
            $0.itemPath.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Change History")
                    .font(.headline)
                    .foregroundStyle(Theme.mainText)
                Spacer()
                Text("\(changeTracker.records.count) entries")
                    .font(.caption)
                    .foregroundStyle(Theme.dimText)
                Button("Close") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            }

            TextField("Search history", text: $query)
                .textFieldStyle(.roundedBorder)

            if filtered.isEmpty {
                Text("No change history yet.")
                    .foregroundStyle(Theme.dimText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filtered) {
                    TableColumn("Item") { record in
                        Text(record.itemName).foregroundStyle(Theme.mainText)
                    }
                    TableColumn("Action") { record in
                        Text(record.action.displayName).foregroundStyle(Theme.dimText)
                    }
                    TableColumn("Attribute") { record in
                        Text(record.attributeChanged).foregroundStyle(Theme.dimText)
                    }
                    TableColumn("Previous") { record in
                        Text(record.previousValue).foregroundStyle(Theme.faintText).lineLimit(1)
                    }
                    TableColumn("New") { record in
                        Text(record.newValue).foregroundStyle(Theme.accentGreen).lineLimit(1)
                    }
                    TableColumn("When") { record in
                        Text(DateFormatters.shortDateTime.string(from: record.timestamp))
                            .foregroundStyle(Theme.dimText)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 760, height: 480)
        .background(Theme.background2)
    }
}
