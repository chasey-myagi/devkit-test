import SwiftUI

struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    @State private var viewModel = IssueDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        statusBadge
                    }
                    Text(issue.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()

                // Labels
                if !issue.labels.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(issue.labels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Metadata
                GroupBox("Details") {
                    LabeledContent("Severity", value: issue.severity ?? "—")
                    LabeledContent("Priority", value: issue.priority ?? "—")
                    LabeledContent("Customer", value: issue.customer ?? "—")
                    LabeledContent("Milestone", value: issue.milestone ?? "—")
                    LabeledContent("Updated", value: issue.updatedAt.formatted())
                }

                // Attachments
                if !issue.attachmentURLs.isEmpty {
                    GroupBox("Attachments (\(issue.attachmentURLs.count))") {
                        ForEach(issue.attachmentURLs, id: \.self) { url in
                            HStack {
                                Image(systemName: "paperclip")
                                Text(URL(string: url)?.lastPathComponent ?? url)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }

                        Button("Download All") {
                            Task {
                                await viewModel.downloadAttachments(
                                    urls: issue.attachmentURLs,
                                    to: "\(NSHomeDirectory())/MOI/moi/issues/\(issue.number)/files"
                                )
                            }
                        }
                        .disabled(viewModel.isDownloading)
                    }
                }

                // Comments
                GroupBox("Comments (\(viewModel.comments.count))") {
                    if viewModel.isLoadingComments {
                        ProgressView()
                    } else if viewModel.comments.isEmpty {
                        Text("No comments")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.author.login)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Text(comment.body)
                                    .font(.callout)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("#\(issue.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, issueNumber: issue.number)
        }
    }

    private var statusBadge: some View {
        Text(issue.projectStatus)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch issue.projectStatus {
        case "In Progress": return .blue
        case "Done": return .green
        default: return .secondary
        }
    }
}

// Simple flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
