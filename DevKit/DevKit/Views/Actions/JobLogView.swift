import SwiftUI

/// Job 列表 + 日志查看
struct JobLogView: View {
    let workspace: Workspace
    let run: GHWorkflowRun
    var viewModel: ActionsViewModel?

    var body: some View {
        HSplitView {
            // 左侧：Jobs 列表
            jobListPanel

            // 右侧：日志内容
            logPanel
        }
        .background(DKColor.Surface.primary)
        .navigationTitle(run.displayTitle)
        .task { await viewModel?.loadJobs(repo: workspace.repoFullName, runId: run.id) }
        .toolbar {
            if run.conclusion == "failure" {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel?.rerun(repo: workspace.repoFullName, runId: run.id) }
                    } label: {
                        Label("Re-run Failed", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(DKPrimaryButtonStyle())
                }
            }
        }
    }

    // MARK: - Jobs 列表

    private var jobListPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack {
                Text("Jobs")
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Text("\(viewModel?.selectedRunJobs.count ?? 0)")
                    .font(DKTypography.caption())
                    .padding(.horizontal, DKSpacing.sm)
                    .padding(.vertical, DKSpacing.xxs)
                    .background(DKColor.Surface.tertiary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)

            Divider()

            List(viewModel?.selectedRunJobs ?? []) { job in
                Button {
                    Task { await viewModel?.loadJobLog(repo: workspace.repoFullName, jobId: job.id) }
                } label: {
                    HStack(spacing: DKSpacing.sm) {
                        Image(systemName: job.statusIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(jobStatusColor(job))
                            .frame(width: 20)
                        Text(job.name)
                            .font(DKTypography.body())
                            .foregroundStyle(DKColor.Foreground.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, maxWidth: 280)
    }

    // MARK: - 日志面板

    private var logPanel: some View {
        Group {
            if viewModel?.isLoadingLog == true {
                ProgressView("Loading log...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let log = viewModel?.jobLog, !log.isEmpty {
                ScrollView([.horizontal, .vertical]) {
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(DKColor.Foreground.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DKSpacing.md)
                }
                .background(DKColor.Surface.secondary)
            } else {
                DKEmptyStateView(
                    icon: "doc.text",
                    title: "Select a job",
                    subtitle: "Choose a job from the list to view its log"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private func jobStatusColor(_ job: GHWorkflowJob) -> Color {
        switch job.status {
        case "completed":
            switch job.conclusion {
            case "success": return DKColor.Accent.positive
            case "failure": return DKColor.Accent.critical
            case "cancelled", "skipped": return DKColor.Foreground.tertiary
            default: return DKColor.Foreground.secondary
            }
        case "in_progress": return DKColor.Accent.warning
        case "queued": return DKColor.Accent.info
        default: return DKColor.Foreground.secondary
        }
    }
}
