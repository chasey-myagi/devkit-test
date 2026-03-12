import SwiftUI

struct PRDetailView: View {
    let pr: CachedPR
    let repoFullName: String
    @State private var viewModel = PRDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(pr.number)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        columnBadge
                        if pr.isDraft {
                            draftBadge
                        }
                    }
                    Text(pr.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()

                // Diff Stats
                GroupBox("Diff Statistics") {
                    HStack(spacing: 24) {
                        Label("+\(pr.additions)", systemImage: "plus.circle.fill")
                            .foregroundStyle(.green)
                        Label("-\(pr.deletions)", systemImage: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.body)
                }

                // Status
                GroupBox("Status") {
                    LabeledContent("Review", value: reviewDisplayText)
                    LabeledContent("CI Checks", value: checksDisplayText)
                    LabeledContent("Board Column", value: pr.boardColumn)
                    LabeledContent("Updated", value: pr.updatedAt.formatted())
                }

                // Linked Issues
                if !pr.linkedIssueNumbers.isEmpty {
                    GroupBox("Linked Issues") {
                        ForEach(pr.linkedIssueNumbers, id: \.self) { issueNumber in
                            HStack {
                                Image(systemName: "link")
                                Text("#\(issueNumber)")
                                Spacer()
                            }
                        }
                    }
                }

                // Comments
                GroupBox("Review Comments (\(viewModel.comments.count))") {
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

                // Open in GitHub button
                Button {
                    let urlString = "https://github.com/\(repoFullName)/pull/\(pr.number)"
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open in GitHub", systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)

                Divider()

                // Merge Section
                mergeSection
            }
            .padding()
        }
        .navigationTitle("#\(pr.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, prNumber: pr.number)
            await viewModel.checkMergeability(repo: repoFullName, prNumber: pr.number)
        }
    }

    // MARK: - Merge Section

    @ViewBuilder
    private var mergeSection: some View {
        GroupBox("Merge") {
            VStack(alignment: .leading, spacing: 12) {
                // Merge success
                if let successMsg = viewModel.mergeSuccessMessage {
                    Label(successMsg, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                }

                // Merge error
                if let errorMsg = viewModel.mergeError {
                    Label(errorMsg, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                // Mergeability status
                if viewModel.isCheckingMergeability {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking mergeability...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if let m = viewModel.mergeability, !m.canMerge {
                    Label(m.reasonText, systemImage: "xmark.circle")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }

                // Merge buttons
                HStack(spacing: 12) {
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
                    .buttonStyle(.borderedProminent)
                    .disabled(!mergeButtonsEnabled)

                    Button {
                        Task {
                            await viewModel.merge(repo: repoFullName, prNumber: pr.number, method: .rebase)
                        }
                    } label: {
                        Label("Rebase & Merge", systemImage: "arrow.triangle.branch")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!mergeButtonsEnabled)

                    Spacer()

                    Button {
                        Task {
                            await viewModel.checkMergeability(repo: repoFullName, prNumber: pr.number)
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
            }
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
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(columnColor.opacity(0.15))
            .foregroundStyle(columnColor)
            .clipShape(Capsule())
    }

    private var draftBadge: some View {
        Text("Draft")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.15))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }

    private var columnColor: Color {
        switch pr.boardColumn {
        case "Draft": return .secondary
        case "In Review": return .blue
        case "Need Fix": return .orange
        case "Ready": return .green
        default: return .secondary
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
