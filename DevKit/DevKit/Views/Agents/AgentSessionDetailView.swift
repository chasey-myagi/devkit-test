import SwiftUI
import SwiftData

struct AgentSessionDetailView: View {
    let sessionID: UUID
    let coordinator: AgentCoordinator?

    @Query private var sessions: [AgentSession]

    private var session: AgentSession? {
        sessions.first { $0.id == sessionID }
    }

    private var worker: AgentWorker? {
        coordinator?.workers.first { $0.currentSession?.id == sessionID }
    }

    init(sessionID: UUID, coordinator: AgentCoordinator?) {
        self.sessionID = sessionID
        self.coordinator = coordinator
        _sessions = Query()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let session {
                statusBar(session)
                Divider()
                terminalArea(session)
            } else {
                ContentUnavailableView("Session Not Found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle(session.map { "Issue #\($0.issueNumber): \($0.issueTitle)" } ?? "Session")
        .toolbar {
            if let session {
                ToolbarItem(placement: .primaryAction) {
                    interventionButton(session)
                }
            }
        }
    }

    // MARK: - Status Bar

    private func statusBar(_ session: AgentSession) -> some View {
        HStack(spacing: DKSpacing.lg) {
            HStack(spacing: DKSpacing.xs) {
                Circle()
                    .fill(statusColor(session.status))
                    .frame(width: 8, height: 8)
                Text(session.status.rawValue.capitalized)
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.primary)
            }
            if let startedAt = session.startedAt {
                Text(elapsedTime(since: startedAt))
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
            Spacer()
            if let pr = session.prNumber {
                Text("PR #\(pr)")
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Accent.brand)
            }
        }
        .padding(.horizontal, DKSpacing.lg)
        .padding(.vertical, DKSpacing.sm)
        .background(DKColor.Surface.secondary)
    }

    // MARK: - Terminal

    private func terminalArea(_ session: AgentSession) -> some View {
        Group {
            if let termView = worker?.terminalView {
                TerminalView(terminalView: termView)
            } else {
                VStack(spacing: DKSpacing.md) {
                    DKEmptyStateView(
                        icon: "terminal",
                        title: "终端未激活",
                        subtitle: session.status == .needsIntervention
                            ? "点击「介入」恢复 Claude Code 会话"
                            : "该会话已结束"
                    )
                }
            }
        }
    }

    // MARK: - Intervention

    @ViewBuilder
    private func interventionButton(_ session: AgentSession) -> some View {
        switch session.status {
        case .running:
            Button("介入") {
                worker?.enableInteraction()
            }
            .buttonStyle(DKSecondaryButtonStyle())
        case .needsIntervention:
            Button("介入") {
                coordinator?.resumeSession(session)
            }
            .buttonStyle(DKPrimaryButtonStyle())
        case .intervening:
            Button("结束介入") {
                worker?.release()
            }
            .buttonStyle(DKGhostButtonStyle())
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private func statusColor(_ status: AgentSessionStatus) -> Color {
        switch status {
        case .queued: DKColor.Foreground.tertiary
        case .running: DKColor.Accent.positive
        case .needsIntervention: DKColor.Accent.warning
        case .intervening: DKColor.Accent.brand
        case .completed: DKColor.Accent.positive
        case .failed: DKColor.Accent.critical
        }
    }

    private func elapsedTime(since date: Date) -> String {
        let seconds = Int(Date.now.timeIntervalSince(date))
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes)m \(secs)s"
    }
}
