import SwiftUI
import SwiftData

struct IssueColumnView: View {
    let title: String
    let status: String
    let issues: [CachedIssue]
    let allIssues: [CachedIssue]
    let onStatusChange: (CachedIssue, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(issues.count)")
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
                    ForEach(issues) { issue in
                        NavigationLink(value: issue) {
                            IssueCardView(issue: issue)
                        }
                        .buttonStyle(.plain)
                        .draggable(String(issue.number))
                    }
                }
                .padding(8)
            }
        }
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .dropDestination(for: String.self) { items, _ in
            guard let numberStr = items.first,
                  let number = Int(numberStr),
                  let issue = allIssues.first(where: { $0.number == number })
            else { return false }
            onStatusChange(issue, status)
            return true
        }
    }
}
