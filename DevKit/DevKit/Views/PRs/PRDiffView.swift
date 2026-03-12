import SwiftUI

/// PR diff 查看器 — 左侧文件列表 + 右侧 diff 内容
struct PRDiffView: View {
    let repo: String
    let prNumber: Int
    @State private var viewModel = PRDiffViewModel()
    @State private var selectedFileId: UUID?

    private var selectedFile: FileDiff? {
        viewModel.files.first { $0.id == selectedFileId }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading diff...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                DKEmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Failed to load diff",
                    subtitle: error
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                DKEmptyStateView(
                    icon: "doc.text",
                    title: "No file changes",
                    subtitle: "This PR has no diff"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    fileListPanel
                    diffContentPanel
                }
            }
        }
        .task { await viewModel.loadDiff(repo: repo, prNumber: prNumber) }
    }

    // MARK: - 文件列表

    private var fileListPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 统计摘要
            HStack(spacing: DKSpacing.md) {
                Text("\(viewModel.files.count) files")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
                Spacer()
                let totalAdd = viewModel.files.reduce(0) { $0 + $1.additions }
                let totalDel = viewModel.files.reduce(0) { $0 + $1.deletions }
                Text("+\(totalAdd)")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.positive)
                Text("-\(totalDel)")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.critical)
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)

            Divider()

            List(viewModel.files, selection: $selectedFileId) { file in
                HStack(spacing: DKSpacing.sm) {
                    fileStatusIcon(file)
                    Text(file.newPath)
                        .font(DKTypography.caption())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if !file.isBinary {
                        Text("+\(file.additions)")
                            .font(DKTypography.captionSmall())
                            .foregroundStyle(DKColor.Accent.positive)
                        Text("-\(file.deletions)")
                            .font(DKTypography.captionSmall())
                            .foregroundStyle(DKColor.Accent.critical)
                    } else {
                        Text("binary")
                            .font(DKTypography.captionSmall())
                            .foregroundStyle(DKColor.Foreground.tertiary)
                    }
                }
                .tag(file.id)
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 250, maxWidth: 350)
    }

    // MARK: - Diff 内容

    private var diffContentPanel: some View {
        Group {
            if let file = selectedFile {
                ScrollView {
                    if file.isBinary {
                        DKEmptyStateView(
                            icon: "doc.fill",
                            title: "Binary file",
                            subtitle: "Cannot display binary content"
                        )
                        .padding(DKSpacing.xl)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(file.hunks) { hunk in
                                hunkHeaderView(hunk)
                                ForEach(hunk.lines) { line in
                                    diffLineView(line)
                                }
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    }
                }
                .background(DKColor.Surface.primary)
            } else {
                DKEmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "Select a file",
                    subtitle: "Choose a file from the list to view changes"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - 行渲染

    private func hunkHeaderView(_ hunk: DiffHunk) -> some View {
        Text(hunk.header)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(DKColor.Foreground.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.xs)
            .background(DKColor.Accent.info.opacity(0.08))
    }

    private func diffLineView(_ line: DiffLine) -> some View {
        HStack(spacing: 0) {
            // 旧文件行号
            Text(line.oldLineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(DKColor.Foreground.tertiary)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, DKSpacing.xs)

            // 新文件行号
            Text(line.newLineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(DKColor.Foreground.tertiary)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, DKSpacing.sm)

            // 前缀符号
            Text(linePrefix(line.type))
                .foregroundStyle(linePrefixColor(line.type))
                .frame(width: 16)

            // 内容
            Text(line.content)
                .foregroundStyle(DKColor.Foreground.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.vertical, 1)
        .background(lineBackground(line.type))
    }

    // MARK: - Helpers

    private func fileStatusIcon(_ file: FileDiff) -> some View {
        Group {
            if file.isNewFile {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(DKColor.Accent.positive)
            } else if file.isDeleted {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(DKColor.Accent.critical)
            } else if file.isBinary {
                Image(systemName: "doc.fill")
                    .foregroundStyle(DKColor.Foreground.tertiary)
            } else {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(DKColor.Accent.warning)
            }
        }
        .font(.system(size: 12))
    }

    private func linePrefix(_ type: DiffLine.LineType) -> String {
        switch type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        }
    }

    private func linePrefixColor(_ type: DiffLine.LineType) -> Color {
        switch type {
        case .addition: return DKColor.Accent.positive
        case .deletion: return DKColor.Accent.critical
        case .context: return .clear
        }
    }

    private func lineBackground(_ type: DiffLine.LineType) -> Color {
        switch type {
        case .addition: return DKColor.Accent.positive.opacity(0.08)
        case .deletion: return DKColor.Accent.critical.opacity(0.08)
        case .context: return .clear
        }
    }
}
