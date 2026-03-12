import SwiftUI

struct PRColumnView: View {
    let title: String
    let prs: [CachedPR]
    let repoFullName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(prs.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Cards
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(prs) { pr in
                        NavigationLink(value: pr) {
                            PRCardView(pr: pr)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
