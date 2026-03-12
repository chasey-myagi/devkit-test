import Foundation
import SwiftData

/// 刷新前后 PR 状态快照，用于检测变化并发送通知
struct PRSnapshot: Sendable {
    var checksStatus: String
    var reviewCount: Int
}

@MainActor
@Observable
final class PRBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let modelContainer: ModelContainer

    /// 是否为首次刷新（首次不发通知，避免通知轰炸）
    private(set) var isFirstRefresh = true
    private(set) var isLoading = false
    private(set) var error: String?

    init(ghClient: GitHubCLIClient, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.modelContainer = modelContainer
    }

    func refresh(workspace: Workspace) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let context = modelContainer.mainContext
            let workspaceName = workspace.name

            // 1. 保存刷新前的状态快照
            let cachedPRs = try context.fetch(FetchDescriptor<CachedPR>(
                predicate: #Predicate { $0.workspaceName == workspaceName }
            ))
            var snapshots: [Int: PRSnapshot] = [:]
            for cached in cachedPRs {
                snapshots[cached.number] = PRSnapshot(
                    checksStatus: cached.checksStatus,
                    reviewCount: cached.reviewCount
                )
            }
            let cachedByNumber = Dictionary(uniqueKeysWithValues: cachedPRs.map { ($0.number, $0) })

            // 2. 拉取远程 PR 数据
            let remotePRs = try await ghClient.fetchAuthoredPRs(repo: workspace.repoFullName)
            let remoteNumbers = Set(remotePRs.map(\.number))

            for remote in remotePRs {
                let linkedIssues = GHPullRequest.extractLinkedIssues(from: remote.body)
                if let cached = cachedByNumber[remote.number] {
                    cached.title = remote.title
                    cached.isDraft = remote.isDraft
                    cached.additions = remote.additions
                    cached.deletions = remote.deletions
                    cached.reviewState = remote.aggregatedReviewState
                    cached.checksStatus = remote.aggregatedChecksStatus
                    cached.linkedIssueNumbers = linkedIssues
                    cached.reviewCount = remote.reviewCount
                    cached.updatedAt = .now
                } else {
                    context.insert(CachedPR(
                        number: remote.number,
                        title: remote.title,
                        isDraft: remote.isDraft,
                        additions: remote.additions,
                        deletions: remote.deletions,
                        reviewState: remote.aggregatedReviewState,
                        checksStatus: remote.aggregatedChecksStatus,
                        linkedIssueNumbers: linkedIssues,
                        reviewCount: remote.reviewCount,
                        workspaceName: workspaceName
                    ))
                }
            }

            // 清理不在远程的 PR
            for cached in cachedPRs where !remoteNumbers.contains(cached.number) {
                context.delete(cached)
            }

            try context.save()

            // 3. 对比前后状态，发通知（首次刷新跳过）
            if isFirstRefresh {
                isFirstRefresh = false
            } else {
                for remote in remotePRs {
                    guard let oldSnapshot = snapshots[remote.number] else { continue }

                    // CI 从非 FAILURE 变为 FAILURE
                    let newChecksStatus = remote.aggregatedChecksStatus
                    if oldSnapshot.checksStatus != "FAILURE" && newChecksStatus == "FAILURE" {
                        NotificationService.shared.sendCIFailureNotification(
                            prNumber: remote.number,
                            title: remote.title
                        )
                    }

                    // reviewCount 增加
                    let newReviewCount = remote.reviewCount
                    if newReviewCount > oldSnapshot.reviewCount {
                        NotificationService.shared.sendNewReviewNotification(
                            prNumber: remote.number,
                            title: remote.title,
                            reviewCount: newReviewCount
                        )
                    }
                }
            }

            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
