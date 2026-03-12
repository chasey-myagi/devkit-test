import SwiftUI

/// GitHub Actions workflow runs 列表
struct ActionsListView: View {
    let workspace: Workspace
    var viewModel: ActionsViewModel?

    var body: some View {
        Group {
            if viewModel?.isLoading == true && (viewModel?.runs.isEmpty ?? true) {
                ProgressView("Loading workflow runs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel?.error, viewModel?.runs.isEmpty ?? true {
                DKEmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Failed to load actions",
                    subtitle: error,
                    buttonTitle: "Retry"
                ) {
                    Task { await viewModel?.loadRuns(repo: workspace.repoFullName) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel?.runs.isEmpty ?? true {
                DKEmptyStateView(
                    icon: "gearshape.2",
                    title: "No workflow runs",
                    subtitle: "No GitHub Actions runs found for this repository"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel?.runs ?? []) { run in
                        NavigationLink(value: run) {
                            runRow(run)
                        }
                        .contextMenu {
                            if run.conclusion == "failure" {
                                Button("Re-run Failed Jobs") {
                                    Task { await viewModel?.rerun(repo: workspace.repoFullName, runId: run.id) }
                                }
                            }
                            Button("Open in Browser") {
                                if let url = URL(string: run.url) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .background(DKColor.Surface.primary)
        .navigationTitle("Actions")
        .navigationDestination(for: GHWorkflowRun.self) { run in
            JobLogView(workspace: workspace, run: run, viewModel: viewModel)
        }
        .task { await viewModel?.loadRuns(repo: workspace.repoFullName) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel?.loadRuns(repo: workspace.repoFullName) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .overlay {
            if viewModel?.isLoading == true && !(viewModel?.runs.isEmpty ?? true) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(DKSpacing.md)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
                            .padding(DKSpacing.lg)
                    }
                }
            }
        }
    }

    // MARK: - Row

    private func runRow(_ run: GHWorkflowRun) -> some View {
        HStack(spacing: DKSpacing.md) {
            Image(systemName: run.statusIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(statusColor(run))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DKSpacing.xxs) {
                Text(run.displayTitle)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                    .lineLimit(1)
                HStack(spacing: DKSpacing.sm) {
                    Label(run.headBranch, systemImage: "arrow.triangle.branch")
                    Text("·")
                    Text(run.event)
                }
                .font(DKTypography.caption())
                .foregroundStyle(DKColor.Foreground.secondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DKSpacing.xxs) {
                Text(run.name)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.tertiary)
                if let date = GHDateParser.parse(run.createdAt) {
                    Text(date, style: .relative)
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Foreground.tertiary)
                }
            }
        }
        .padding(.vertical, DKSpacing.xxs)
    }

    // MARK: - Helpers

    private func statusColor(_ run: GHWorkflowRun) -> Color {
        switch run.status {
        case "completed":
            switch run.conclusion {
            case "success": return DKColor.Accent.positive
            case "failure": return DKColor.Accent.critical
            case "cancelled": return DKColor.Foreground.tertiary
            default: return DKColor.Foreground.secondary
            }
        case "in_progress": return DKColor.Accent.warning
        case "queued": return DKColor.Accent.info
        default: return DKColor.Foreground.secondary
        }
    }
}
