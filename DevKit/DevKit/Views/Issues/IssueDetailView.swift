import SwiftUI

struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    let localPath: String
    @State private var viewModel = IssueDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(DKTypography.pageTitle())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        statusBadge
                    }
                    Text(issue.title)
                        .dkTextStyle(.pageTitle)
                        .foregroundStyle(DKColor.Foreground.primary)
                }

                Divider()

                // Labels
                if !issue.labels.isEmpty {
                    FlowLayout(spacing: DKSpacing.xs) {
                        ForEach(issue.labels, id: \.self) { label in
                            Text(label)
                                .font(DKTypography.caption())
                                .padding(.horizontal, DKSpacing.sm)
                                .padding(.vertical, DKSpacing.xxs)
                                .background(DKColor.Surface.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Metadata card
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Details", icon: "info.circle")
                    VStack(spacing: DKSpacing.xs) {
                        LabeledContent("Severity", value: issue.severity ?? "—")
                        LabeledContent("Priority", value: issue.priority ?? "—")
                        LabeledContent("Customer", value: issue.customer ?? "—")
                        LabeledContent("Milestone", value: issue.milestone ?? "—")
                        LabeledContent("Updated", value: issue.updatedAt.formatted())
                    }
                    .font(DKTypography.body())
                    .foregroundStyle(DKColor.Foreground.primary)
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }

                // Attachments card
                if !issue.attachmentURLs.isEmpty {
                    VStack(alignment: .leading, spacing: DKSpacing.sm) {
                        DKSectionHeader(title: "Attachments (\(issue.attachmentURLs.count))", icon: "paperclip")
                        VStack(alignment: .leading, spacing: DKSpacing.sm) {
                            attachmentStatusView

                            ForEach(Array(issue.attachmentURLs.enumerated()), id: \.offset) { _, url in
                                HStack {
                                    Image(systemName: "paperclip")
                                        .foregroundStyle(DKColor.Foreground.tertiary)
                                    Text(URL(string: url)?.lastPathComponent ?? url)
                                        .font(DKTypography.body())
                                        .foregroundStyle(DKColor.Foreground.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }

                            if issue.attachmentStatus == "downloaded" {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundStyle(DKColor.Foreground.secondary)
                                    Text("\(localPath)/issues/\(issue.number)")
                                        .font(DKTypography.captionSmall())
                                        .foregroundStyle(DKColor.Foreground.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Open in Finder") {
                                        NSWorkspace.shared.open(URL(fileURLWithPath: "\(localPath)/issues/\(issue.number)"))
                                    }
                                    .font(DKTypography.caption())
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
                        .padding(DKSpacing.lg)
                        .background(DKColor.Surface.card)
                        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                        .dkShadow(DKShadow.sm)
                    }
                }

                // Comments card
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Comments (\(viewModel.comments.count))", icon: "text.bubble")
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.isLoadingComments {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(DKSpacing.xl)
                        } else if viewModel.comments.isEmpty {
                            Text("No comments")
                                .font(DKTypography.body())
                                .foregroundStyle(DKColor.Foreground.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(DKSpacing.xl)
                        } else {
                            let lastID = viewModel.comments.last?.id
                            ForEach(viewModel.comments) { comment in
                                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                                    HStack {
                                        Text(comment.author.login)
                                            .font(DKTypography.caption())
                                            .fontWeight(.semibold)
                                            .foregroundStyle(DKColor.Foreground.primary)
                                        Spacer()
                                        if let date = comment.createdDate {
                                            Text(date, style: .relative)
                                                .font(DKTypography.captionSmall())
                                                .foregroundStyle(DKColor.Foreground.tertiary)
                                        } else {
                                            Text(comment.createdAt)
                                                .font(DKTypography.captionSmall())
                                                .foregroundStyle(DKColor.Foreground.tertiary)
                                        }
                                    }
                                    Text(comment.body)
                                        .font(DKTypography.body())
                                        .foregroundStyle(DKColor.Foreground.primary)
                                }
                                .padding(.vertical, DKSpacing.sm)
                                if comment.id != lastID {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }
            }
            .padding(DKSpacing.xl)
        }
        .background(DKColor.Surface.primary)
        .navigationTitle("#\(issue.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, issueNumber: issue.number)
        }
    }

    @ViewBuilder
    private var attachmentStatusView: some View {
        switch issue.attachmentStatus {
        case "downloading":
            HStack(spacing: DKSpacing.sm) {
                ProgressView().controlSize(.small)
                Text("Downloading attachments...")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
        case "downloaded":
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DKColor.Accent.positive)
                Text("All attachments downloaded")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
        case "failed":
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DKColor.Accent.critical)
                Text("Some downloads failed")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.critical)
            }
        default:
            EmptyView()
        }
    }

    private var statusBadge: some View {
        Text(issue.projectStatus)
            .font(DKTypography.caption())
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xxs)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch issue.projectStatus {
        case "In Progress": DKColor.Accent.info
        case "Done": DKColor.Accent.positive
        default: Color.secondary
        }
    }
}

// MARK: - FlowLayout (preserved from original)

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
