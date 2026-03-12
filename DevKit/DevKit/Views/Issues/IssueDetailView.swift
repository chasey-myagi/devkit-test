import SwiftUI

struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    let localPath: String
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
                        // 下载状态指示
                        attachmentStatusView

                        ForEach(Array(issue.attachmentURLs.enumerated()), id: \.offset) { _, url in
                            HStack {
                                Image(systemName: "paperclip")
                                Text(URL(string: url)?.lastPathComponent ?? url)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }

                        // downloaded 时显示本地路径
                        if issue.attachmentStatus == "downloaded" {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                Text("\(localPath)/issues/\(issue.number)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button("Open in Finder") {
                                    NSWorkspace.shared.open(URL(fileURLWithPath: "\(localPath)/issues/\(issue.number)"))
                                }
                                .font(.caption)
                            }
                        }

                        HStack {
                            if issue.attachmentStatus == "failed" {
                                Button("Retry Download") {
                                    Task {
                                        await viewModel.downloadAttachments(
                                            urls: issue.attachmentURLs,
                                            to: "\(localPath)/issues/\(issue.number)"
                                        )
                                        issue.attachmentStatus = viewModel.downloadError == nil ? "downloaded" : "failed"
                                    }
                                }
                            }

                            if issue.attachmentStatus == "none" {
                                Button("Download All") {
                                    Task {
                                        issue.attachmentStatus = "downloading"
                                        await viewModel.downloadAttachments(
                                            urls: issue.attachmentURLs,
                                            to: "\(localPath)/issues/\(issue.number)"
                                        )
                                        issue.attachmentStatus = viewModel.downloadError == nil ? "downloaded" : "failed"
                                    }
                                }
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
                                    if let date = comment.createdDate {
                                        Text(date, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        Text(comment.createdAt)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
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

    @ViewBuilder
    private var attachmentStatusView: some View {
        switch issue.attachmentStatus {
        case "downloading":
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Downloading attachments...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case "downloaded":
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("All attachments downloaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case "failed":
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Some downloads failed")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        default:
            EmptyView()
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
