// DevKit/DevKit/Views/Agents/AgentBoardView.swift
import SwiftUI
import SwiftData

struct AgentBoardView: View {
    let workspace: Workspace
    let coordinator: AgentCoordinator?

    @Query private var sessions: [AgentSession]

    init(workspace: Workspace, coordinator: AgentCoordinator?) {
        self.workspace = workspace
        self.coordinator = coordinator
        let wsName = workspace.name
        _sessions = Query(
            filter: #Predicate<AgentSession> { $0.workspaceName == wsName },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    private var queuedSessions: [AgentSession] {
        sessions.filter { $0.status == .queued }
    }

    private var historySessions: [AgentSession] {
        sessions.filter { $0.status == .completed || $0.status == .failed }
    }

    var body: some View {
        if coordinator?.claudeInstalled == false {
            claudeNotInstalledView
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.lg) {
                workersSection
                if !queuedSessions.isEmpty {
                    queueSection
                }
                if !historySessions.isEmpty {
                    historySection
                }
            }
            .padding(DKSpacing.lg)
        }
    }

    // MARK: - Workers

    private var workersSection: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            DKSectionHeader(title: "Workers", icon: "terminal")
            ForEach(coordinator?.workers ?? [], id: \.id) { worker in
                workerRow(worker)
            }
        }
    }

    private func workerRow(_ worker: AgentWorker) -> some View {
        HStack {
            Circle()
                .fill(worker.isIdle ? DKColor.Foreground.tertiary : DKColor.Accent.positive)
                .frame(width: 8, height: 8)
            Text(worker.id)
                .font(DKTypography.bodyMedium())
                .foregroundStyle(DKColor.Foreground.primary)
            Spacer()
            if let session = worker.currentSession {
                NavigationLink(value: session.id) {
                    Text("Issue #\(session.issueNumber)")
                        .font(DKTypography.caption())
                        .foregroundStyle(DKColor.Accent.brand)
                }
            } else {
                Text("Idle")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.tertiary)
            }
        }
        .padding(DKSpacing.md)
        .background(DKColor.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
    }

    // MARK: - Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            DKSectionHeader(title: "Queue (\(queuedSessions.count))", icon: "list.bullet")
            ForEach(queuedSessions) { session in
                sessionRow(session)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            DKSectionHeader(title: "History", icon: "clock")
            ForEach(historySessions) { session in
                sessionRow(session)
            }
        }
    }

    private func sessionRow(_ session: AgentSession) -> some View {
        NavigationLink(value: session.id) {
            HStack {
                Text("#\(session.issueNumber)")
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Text(session.issueTitle)
                    .font(DKTypography.body())
                    .foregroundStyle(DKColor.Foreground.secondary)
                    .lineLimit(1)
                Spacer()
                statusBadge(session.status)
                if let pr = session.prNumber {
                    Text("PR #\(pr)")
                        .font(DKTypography.caption())
                        .foregroundStyle(DKColor.Accent.brand)
                }
            }
            .padding(DKSpacing.md)
            .background(DKColor.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(_ status: AgentSessionStatus) -> some View {
        let (text, color): (String, Color) = switch status {
        case .queued: ("Queued", DKColor.Foreground.tertiary)
        case .running: ("Running", DKColor.Accent.positive)
        case .needsIntervention: ("Needs Intervention", DKColor.Accent.warning)
        case .intervening: ("Intervening", DKColor.Accent.brand)
        case .completed: ("Completed", DKColor.Accent.positive)
        case .failed: ("Failed", DKColor.Accent.critical)
        }
        return Text(text)
            .font(DKTypography.captionSmall())
            .foregroundStyle(color)
    }

    // MARK: - Not Installed

    private var claudeNotInstalledView: some View {
        DKEmptyStateView(
            icon: "terminal",
            title: "Claude Code 未安装",
            subtitle: "请先安装 Claude Code CLI: npm install -g @anthropic-ai/claude-code"
        )
    }
}
