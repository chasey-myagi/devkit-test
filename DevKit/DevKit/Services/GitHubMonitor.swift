import Foundation
import SwiftData

struct PollChanges: Sendable {
    var newIssues: [GHIssue] = []
    var statusChanges: [StatusChange] = []

    struct StatusChange: Sendable {
        var issueNumber: Int
        var oldStatus: String
        var newStatus: String
    }
}

/// Resolves project status for an issue. Default impl calls GitHub GraphQL.
/// Tests inject a mock closure.
typealias StatusResolver = @Sendable (String, Int) async throws -> String

@MainActor
@Observable
final class GitHubMonitor {
    private let ghClient: GitHubCLIClient
    private let modelContainer: ModelContainer
    private(set) var isPolling = false
    private(set) var lastPollDate: Date?
    private(set) var lastError: String?
    private(set) var consecutiveFailures = 0
    private var pollTimer: Timer?
    /// 首次 poll 标志：首次同步时不发通知，避免通知轰炸
    private var isFirstPoll = true
    /// 每次 timer 轮询完成后执行的额外工作（如刷新 PR）
    private var onPollComplete: (() async -> Void)?

    init(ghClient: GitHubCLIClient, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.modelContainer = modelContainer
    }

    func startPolling(
        repo: String,
        workspaceName: String,
        interval: TimeInterval,
        onPollComplete: (() async -> Void)? = nil
    ) {
        stopPolling()
        self.onPollComplete = onPollComplete
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                _ = try? await self.poll(repo: repo, workspaceName: workspaceName)
                await self.onPollComplete?()
            }
        }
        Task {
            _ = try? await poll(repo: repo, workspaceName: workspaceName)
            await onPollComplete?()
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        onPollComplete = nil
    }

    /// statusResolver defaults to calling ghClient.fetchProjectStatus.
    /// Tests inject a mock closure.
    func poll(
        repo: String,
        workspaceName: String,
        statusResolver: StatusResolver? = nil
    ) async throws -> PollChanges {
        isPolling = true
        defer {
            isPolling = false
            lastPollDate = .now
        }

        let resolver = statusResolver ?? { [ghClient] repo, issueNumber in
            try await ghClient.fetchProjectStatus(repo: repo, issueNumber: issueNumber)
        }

        let remoteIssues: [GHIssue]
        do {
            remoteIssues = try await ghClient.fetchAssignedIssues(repo: repo)
            consecutiveFailures = 0
        } catch {
            consecutiveFailures += 1
            lastError = error.localizedDescription
            // I-2: 连续 3 次失败发通知
            if consecutiveFailures == 3 {
                NotificationService.shared.sendConsecutiveFailureNotification(
                    failures: consecutiveFailures
                )
            }
            throw error
        }

        // Batch resolve statuses concurrently with TaskGroup
        let statusMap: [Int: String] = await withTaskGroup(of: (Int, String).self) { group in
            for remote in remoteIssues {
                group.addTask {
                    let status = (try? await resolver(repo, remote.number)) ?? "To Do"
                    return (remote.number, status)
                }
            }
            var map = [Int: String]()
            for await (number, status) in group {
                map[number] = status
            }
            return map
        }

        let context = modelContainer.mainContext
        let cachedIssues = try context.fetch(FetchDescriptor<CachedIssue>(
            predicate: #Predicate { $0.workspaceName == workspaceName }
        ))
        let cachedByNumber = Dictionary(uniqueKeysWithValues: cachedIssues.map { ($0.number, $0) })

        var changes = PollChanges()

        for remote in remoteIssues {
            let parsed = LabelParser.parse(remote.labels.map(\.name))
            let attachmentURLs = GHIssue.extractAttachmentURLs(from: remote.body)
            let status = statusMap[remote.number] ?? "To Do"

            if let cached = cachedByNumber[remote.number] {
                if cached.projectStatus != status {
                    changes.statusChanges.append(.init(
                        issueNumber: remote.number,
                        oldStatus: cached.projectStatus,
                        newStatus: status
                    ))
                }
                cached.title = remote.title
                cached.labels = remote.labels.map(\.name)
                cached.severity = parsed.severity
                cached.priority = parsed.priority
                cached.customer = parsed.customer
                cached.projectStatus = status
                cached.assignees = remote.assignees.map(\.login)
                cached.milestone = remote.milestone?.title
                cached.attachmentURLs = attachmentURLs
                cached.updatedAt = remote.parsedUpdatedAt
            } else {
                changes.newIssues.append(remote)
                let newCached = CachedIssue(
                    number: remote.number,
                    title: remote.title,
                    labels: remote.labels.map(\.name),
                    severity: parsed.severity,
                    priority: parsed.priority,
                    customer: parsed.customer,
                    projectStatus: status,
                    assignees: remote.assignees.map(\.login),
                    milestone: remote.milestone?.title,
                    attachmentURLs: attachmentURLs,
                    updatedAt: remote.parsedUpdatedAt,
                    workspaceName: workspaceName
                )
                context.insert(newCached)
            }
        }

        // Remove stale issues no longer in remote set
        let remoteNumbers = Set(remoteIssues.map(\.number))
        for cached in cachedIssues where !remoteNumbers.contains(cached.number) {
            context.delete(cached)
        }

        // Build reverse mapping: issue number -> [PR numbers] from CachedPR data
        let cachedPRs = try context.fetch(FetchDescriptor<CachedPR>(
            predicate: #Predicate { $0.workspaceName == workspaceName }
        ))
        var issueToLinkedPRs: [Int: [Int]] = [:]
        for pr in cachedPRs {
            for issueNum in pr.linkedIssueNumbers {
                issueToLinkedPRs[issueNum, default: []].append(pr.number)
            }
        }

        // Refresh all cached issues' linkedPRNumbers
        let allCachedIssues = try context.fetch(FetchDescriptor<CachedIssue>(
            predicate: #Predicate { $0.workspaceName == workspaceName }
        ))
        for cached in allCachedIssues {
            let linked = issueToLinkedPRs[cached.number] ?? []
            if cached.linkedPRNumbers != linked {
                cached.linkedPRNumbers = linked
            }
        }

        try context.save()

        // 首次 poll 跳过通知（避免应用启动时对已有 issue 发一堆通知）
        if isFirstPoll {
            isFirstPoll = false
        } else {
            for newIssue in changes.newIssues {
                NotificationService.shared.sendNewIssueNotification(
                    issueNumber: newIssue.number,
                    title: newIssue.title
                )
            }
            for statusChange in changes.statusChanges {
                NotificationService.shared.sendStatusChangeNotification(
                    issueNumber: statusChange.issueNumber,
                    oldStatus: statusChange.oldStatus,
                    newStatus: statusChange.newStatus
                )
            }
        }

        lastError = nil
        return changes
    }
}
