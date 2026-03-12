import SwiftUI

struct PRDetailView: View {
    let pr: CachedPR
    let repoFullName: String
    @State private var viewModel = PRDetailViewModel()
    @State private var activeTab: PRDetailTab = .overview

    /// PR 详情页的 tab 类型
    enum PRDetailTab: String, CaseIterable {
        case overview = "Overview"
        case diff = "Files Changed"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header + Tab 切换
            VStack(alignment: .leading, spacing: DKSpacing.sm) {
                // Header
                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                    HStack {
                        Text("#\(pr.number)")
                            .font(DKTypography.pageTitle())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        columnBadge
                        if pr.isDraft {
                            draftBadge
                        }
                    }
                    Text(pr.title)
                        .dkTextStyle(.pageTitle)
                        .foregroundStyle(DKColor.Foreground.primary)
                }
                .padding(.horizontal, DKSpacing.xl)
                .padding(.top, DKSpacing.xl)

                // Tab 选择器
                Picker("", selection: $activeTab) {
                    ForEach(PRDetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DKSpacing.xl)
            }

            Divider()

            // Tab 内容
            switch activeTab {
            case .overview:
                overviewContent
            case .diff:
                PRDiffView(repo: repoFullName, prNumber: pr.number)
            }
        }
        .background(DKColor.Surface.primary)
        .navigationTitle("#\(pr.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, prNumber: pr.number)
            await viewModel.checkMergeability(repo: repoFullName, prNumber: pr.number)
        }
    }

    // MARK: - Overview 内容

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.xl) {

                Divider()

                // Diff Statistics card
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Diff Statistics", icon: "chart.bar")
                    HStack(spacing: DKSpacing.xl) {
                        Label("+\(pr.additions)", systemImage: "plus.circle.fill")
                            .foregroundStyle(DKColor.Accent.positive)
                        Label("-\(pr.deletions)", systemImage: "minus.circle.fill")
                            .foregroundStyle(DKColor.Accent.critical)
                    }
                    .font(DKTypography.body())
                    .padding(DKSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }

                // Status card
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Status", icon: "info.circle")
                    VStack(spacing: DKSpacing.xs) {
                        LabeledContent("Review", value: reviewDisplayText)
                        LabeledContent("CI Checks", value: checksDisplayText)
                        LabeledContent("Board Column", value: pr.boardColumn)
                        LabeledContent("Updated", value: pr.updatedAt.formatted())
                    }
                    .font(DKTypography.body())
                    .foregroundStyle(DKColor.Foreground.primary)
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }

                // Linked Issues card
                if !pr.linkedIssueNumbers.isEmpty {
                    VStack(alignment: .leading, spacing: DKSpacing.sm) {
                        DKSectionHeader(title: "Linked Issues", icon: "link")
                        VStack(spacing: DKSpacing.xs) {
                            ForEach(pr.linkedIssueNumbers, id: \.self) { issueNumber in
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundStyle(DKColor.Foreground.tertiary)
                                    Text("#\(issueNumber)")
                                        .font(DKTypography.body())
                                        .foregroundStyle(DKColor.Foreground.primary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(DKSpacing.lg)
                        .background(DKColor.Surface.card)
                        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                        .dkShadow(DKShadow.sm)
                    }
                }

                // Review Comments card
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Review Comments (\(viewModel.comments.count))", icon: "text.bubble")
                    VStack(alignment: .leading, spacing: DKSpacing.md) {
                        CommentListView(
                            comments: viewModel.comments,
                            isLoading: viewModel.isLoadingComments
                        )

                        Divider()

                        // 评论输入
                        CommentInputView(
                            text: $viewModel.newCommentText,
                            isPosting: viewModel.isPostingComment
                        ) {
                            Task {
                                await viewModel.postComment(repo: repoFullName, prNumber: pr.number)
                            }
                        }
                    }
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }

                // Open in GitHub
                Button {
                    let urlString = "https://github.com/\(repoFullName)/pull/\(pr.number)"
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open in GitHub", systemImage: "safari")
                }
                .buttonStyle(DKSecondaryButtonStyle())

                Divider()

                // Merge Section
                mergeSection
            }
            .padding(DKSpacing.xl)
        }
    }

    // MARK: - Merge Section

    @ViewBuilder
    private var mergeSection: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            DKSectionHeader(title: "Merge", icon: "arrow.triangle.merge")
            VStack(alignment: .leading, spacing: DKSpacing.md) {
                // Merge success
                if let successMsg = viewModel.mergeSuccessMessage {
                    Label(successMsg, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(DKColor.Accent.positive)
                        .font(DKTypography.body())
                }

                // Merge error
                if let errorMsg = viewModel.mergeError {
                    Label(errorMsg, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(DKColor.Accent.critical)
                        .font(DKTypography.body())
                }

                // Mergeability status
                if viewModel.isCheckingMergeability {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking mergeability...")
                            .font(DKTypography.body())
                            .foregroundStyle(DKColor.Foreground.secondary)
                    }
                } else if let m = viewModel.mergeability, !m.canMerge {
                    Label(m.reasonText, systemImage: "xmark.circle")
                        .foregroundStyle(DKColor.Accent.warning)
                        .font(DKTypography.body())
                }

                // Merge buttons
                HStack(spacing: DKSpacing.md) {
                    Button {
                        Task {
                            await viewModel.merge(repo: repoFullName, prNumber: pr.number, method: .squash)
                        }
                    } label: {
                        if viewModel.isMerging {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Squash & Merge", systemImage: "arrow.triangle.merge")
                        }
                    }
                    .buttonStyle(DKPrimaryButtonStyle())
                    .disabled(!mergeButtonsEnabled)

                    Button {
                        Task {
                            await viewModel.merge(repo: repoFullName, prNumber: pr.number, method: .rebase)
                        }
                    } label: {
                        Label("Rebase & Merge", systemImage: "arrow.triangle.branch")
                    }
                    .buttonStyle(DKSecondaryButtonStyle())
                    .disabled(!mergeButtonsEnabled)

                    Spacer()

                    Button {
                        Task {
                            await viewModel.checkMergeability(repo: repoFullName, prNumber: pr.number)
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(DKGhostButtonStyle())
                }
            }
            .padding(DKSpacing.lg)
            .background(DKColor.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
            .dkShadow(DKShadow.sm)
        }
    }

    private var mergeButtonsEnabled: Bool {
        guard viewModel.mergeSuccessMessage == nil else { return false }
        guard !viewModel.isMerging else { return false }
        guard !viewModel.isCheckingMergeability else { return false }
        guard let m = viewModel.mergeability else { return false }
        return m.canMerge
    }

    // MARK: - Helpers

    private var columnBadge: some View {
        Text(pr.boardColumn)
            .font(DKTypography.caption())
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xxs)
            .background(columnColor.opacity(0.15))
            .foregroundStyle(columnColor)
            .clipShape(Capsule())
    }

    private var draftBadge: some View {
        Text("Draft")
            .font(DKTypography.caption())
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xxs)
            .background(Color.secondary.opacity(0.15))
            .foregroundStyle(Color.secondary)
            .clipShape(Capsule())
    }

    private var columnColor: Color {
        switch pr.boardColumn {
        case "Draft": return Color.secondary
        case "In Review": return DKColor.Accent.info
        case "Need Fix": return DKColor.Accent.warning
        case "Ready": return DKColor.Accent.positive
        default: return Color.secondary
        }
    }

    private var reviewDisplayText: String {
        switch pr.reviewState {
        case "APPROVED": return "Approved"
        case "CHANGES_REQUESTED": return "Changes Requested"
        default: return "Pending"
        }
    }

    private var checksDisplayText: String {
        switch pr.checksStatus {
        case "SUCCESS": return "All Passed"
        case "FAILURE": return "Failed"
        default: return "Pending"
        }
    }
}
