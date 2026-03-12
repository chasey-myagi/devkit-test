import Foundation
import SwiftData
import os

@MainActor
@Observable
final class AgentCoordinator {
    private(set) var workers: [AgentWorker] = []
    private(set) var notifyServer: AgentNotifyServer
    private let configurator: AgentWorkspaceConfigurator
    private let ghClient: GitHubCLIClient
    nonisolated private let logger = Logger(subsystem: "com.chasey.DevKit", category: "AgentCoordinator")
    private var modelContainer: ModelContainer?

    var claudeInstalled = false

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        let server = AgentNotifyServer()
        self.notifyServer = server
        self.configurator = AgentWorkspaceConfigurator(port: server.port)
        self.ghClient = ghClient
    }

    func setup(modelContainer: ModelContainer, maxConcurrency: Int) {
        self.modelContainer = modelContainer
        workers = (0..<maxConcurrency).map { AgentWorker(id: "worker-\($0)") }

        notifyServer.onEvent = { [weak self] event in
            self?.handleHookEvent(event)
        }
        try? notifyServer.start()

        Task {
            let detector = ClaudeCLIDetector()
            let status = await detector.detect()
            claudeInstalled = status.isInstalled
        }

        recoverStaleSessions()
    }

    func enqueue(issue: CachedIssue, workspace: Workspace) {
        guard claudeInstalled else {
            logger.warning("Claude CLI not installed, skipping enqueue for issue #\(issue.number)")
            return
        }

        guard let container = modelContainer else { return }
        let context = container.mainContext

        // Check if session already exists
        let issueNum = issue.number
        let wsName = workspace.name
        let descriptor = FetchDescriptor<AgentSession>(
            predicate: #Predicate { $0.issueNumber == issueNum && $0.workspaceName == wsName }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty { return }

        let session = AgentSession(
            workspaceName: workspace.name,
            issueNumber: issue.number,
            issueTitle: issue.title
        )
        context.insert(session)
        try? context.save()

        // Configure workspace hooks and skill
        do {
            try configurator.ensureHookConfig(at: workspace.localPath)
            try configurator.ensureSkill(at: workspace.localPath, content: Self.defaultSkillContent)
        } catch {
            logger.error("Failed to configure workspace at \(workspace.localPath): \(error). Agent events may not be received.")
        }

        dispatch(workspace: workspace)
    }

    func dispatch(workspace: Workspace) {
        guard let worker = workers.first(where: { $0.isIdle }) else { return }
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let wsName = workspace.name
        let queuedRaw = AgentSessionStatus.queued.rawValue
        let descriptor = FetchDescriptor<AgentSession>(
            predicate: #Predicate { $0.workspaceName == wsName && $0.statusRaw == queuedRaw },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        guard let session = try? context.fetch(descriptor).first else { return }

        // Fetch full issue data from CachedIssue
        let issueNum = session.issueNumber
        let issueDescriptor = FetchDescriptor<CachedIssue>(
            predicate: #Predicate { $0.number == issueNum && $0.workspaceName == wsName }
        )
        let cachedIssue = try? context.fetch(issueDescriptor).first

        let prompt = PromptTemplateRenderer.render(
            template: workspace.agentPromptTemplate,
            issueNumber: session.issueNumber,
            issueTitle: session.issueTitle,
            issueBody: cachedIssue?.bodyHTML ?? "",
            issueLabels: cachedIssue?.labels ?? [],
            repo: workspace.repoFullName,
            attachments: []
        )

        worker.start(session: session, workspacePath: workspace.localPath, prompt: prompt)
        try? context.save()
    }

    // MARK: - Hook Event Handling

    private func handleHookEvent(_ event: AgentHookEvent) {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        // Find session by matching UUID string
        let allDescriptor = FetchDescriptor<AgentSession>()
        guard let allSessions = try? context.fetch(allDescriptor),
              let session = allSessions.first(where: { $0.id.uuidString == event.sessionID }) else {
            logger.warning("Received hook for unknown session: \(event.sessionID)")
            return
        }

        switch event.type {
        case .stop:
            // Worker release happens inside handleStopEvent Task after async PR check completes
            handleStopEvent(session: session)
        case .notification:
            // Keep worker alive so user can interact via terminal
            session.status = .needsIntervention
            try? context.save()
            NotificationService.shared.sendAgentNeedsInterventionNotification(
                issueNumber: session.issueNumber,
                issueTitle: session.issueTitle
            )
        }
    }

    private func handleStopEvent(session: AgentSession) {
        // Capture values before entering Task to avoid cross-actor issues
        let wsName = session.workspaceName
        let issueNumber = session.issueNumber
        let issueTitle = session.issueTitle
        let sessionID = session.id

        Task { @MainActor [weak self] in
            guard let self, let container = modelContainer else { return }
            let context = container.mainContext

            let wsDescriptor = FetchDescriptor<Workspace>(
                predicate: #Predicate { $0.name == wsName }
            )
            guard let workspace = try? context.fetch(wsDescriptor).first else { return }

            let prs = try? await ghClient.fetchAuthoredPRs(repo: workspace.repoFullName)
            let linkedPR = prs?.first { $0.title.contains("#\(issueNumber)") || $0.body?.contains("Closes #\(issueNumber)") == true }

            if let linkedPR {
                session.status = .completed
                session.prNumber = linkedPR.number
                try? context.save()
                NotificationService.shared.sendAgentCompletedNotification(
                    issueNumber: issueNumber,
                    issueTitle: issueTitle,
                    prNumber: linkedPR.number
                )
            } else {
                session.status = .needsIntervention
                try? context.save()
                NotificationService.shared.sendAgentNeedsInterventionNotification(
                    issueNumber: issueNumber,
                    issueTitle: issueTitle
                )
            }

            // Release worker AFTER async PR check completes
            if let worker = workers.first(where: { $0.currentSession?.id == sessionID }) {
                worker.release()
            }
        }
    }

    // MARK: - Recovery

    private func recoverStaleSessions() {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let runningRaw = AgentSessionStatus.running.rawValue
        let interveningRaw = AgentSessionStatus.intervening.rawValue
        let descriptor = FetchDescriptor<AgentSession>(
            predicate: #Predicate { $0.statusRaw == runningRaw || $0.statusRaw == interveningRaw }
        )
        guard let stale = try? context.fetch(descriptor) else { return }
        for session in stale {
            session.status = .needsIntervention
            logger.info("Recovered stale session for issue #\(session.issueNumber)")
        }
        try? context.save()
    }

    // MARK: - Intervention

    func resumeSession(_ session: AgentSession) {
        guard let worker = workers.first(where: { $0.isIdle }) else {
            logger.warning("No idle worker available to resume session for issue #\(session.issueNumber)")
            return
        }
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let wsName = session.workspaceName
        let wsDescriptor = FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.name == wsName }
        )
        guard let workspace = try? context.fetch(wsDescriptor).first else { return }

        worker.resume(session: session, workspacePath: workspace.localPath)
        try? context.save()
    }

    func stop() {
        notifyServer.stop()
    }

    // MARK: - Default Skill

    static let defaultSkillContent = """
    ## 自动解决 GitHub Issue 的标准流程

    1. 仔细阅读 Issue 描述和标签，理解需求
    2. 分析相关代码，确定修改方案
    3. 编写代码实现修复或功能
    4. 确保代码通过编译和现有测试
    5. 如有必要，添加新的测试用例
    6. 创建一个 Pull Request，标题包含 Issue 编号（如 "Fix #42: ..."）
    7. PR 描述中使用 "Closes #<issue_number>" 来关联 Issue

    ### 注意事项
    - 遵循项目现有的代码风格和约定
    - 保持改动范围最小化，只修改必要的部分
    - 如果遇到无法解决的问题，停下来等待用户介入
    """
}
