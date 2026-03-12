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
    var isPolling = false
    var lastPollDate: Date?
    var lastError: String?
    var consecutiveFailures = 0
    private var pollTimer: Timer?

    init(ghClient: GitHubCLIClient, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.modelContainer = modelContainer
    }

    func startPolling(repo: String, workspaceName: String, interval: TimeInterval) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                _ = try? await self.poll(repo: repo, workspaceName: workspaceName)
            }
        }
        Task {
            _ = try? await poll(repo: repo, workspaceName: workspaceName)
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
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
            throw error
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
            let status = (try? await resolver(repo, remote.number)) ?? "To Do"

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
                cached.updatedAt = .now
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
                    workspaceName: workspaceName
                )
                context.insert(newCached)
            }
        }

        try context.save()
        lastError = nil
        return changes
    }
}
