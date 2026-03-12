import Foundation
import os
import UserNotifications

private let logger = Logger(subsystem: "com.chasey.DevKit", category: "NotificationService")

/// macOS 原生通知服务
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// 请求通知权限
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                logger.warning("Notification permission denied")
            }
        } catch {
            logger.error("Notification authorization error: \(error)")
        }
    }

    /// 新 issue 被 assign 给当前用户时发送通知
    func sendNewIssueNotification(issueNumber: Int, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Issue Assigned"
        content.body = "#\(issueNumber): \(title)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-issue-\(issueNumber)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver new-issue notification #\(issueNumber): \(error)")
            }
        }
    }

    /// Issue 状态变更时发送通知
    func sendStatusChangeNotification(issueNumber: Int, oldStatus: String, newStatus: String) {
        let content = UNMutableNotificationContent()
        content.title = "Issue Status Changed"
        content.body = "#\(issueNumber): \(oldStatus) → \(newStatus)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "status-change-\(issueNumber)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver status-change notification #\(issueNumber): \(error)")
            }
        }
    }

    /// PR CI 检查失败时发送通知
    func sendCIFailureNotification(prNumber: Int, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "CI Failed"
        content.body = "PR #\(prNumber): \(title)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "ci-failure-\(prNumber)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver CI failure notification #\(prNumber): \(error)")
            }
        }
    }

    /// PR 有新的 review comment 时发送通知
    func sendNewReviewNotification(prNumber: Int, title: String, reviewCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "New Review"
        content.body = "PR #\(prNumber): \(title) (\(reviewCount) reviews)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-review-\(prNumber)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver new review notification #\(prNumber): \(error)")
            }
        }
    }

    /// GitHub API rate limit 时发送通知
    func sendRateLimitNotification(resumeAt: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: resumeAt)

        let content = UNMutableNotificationContent()
        content.title = "GitHub Rate Limited"
        content.body = "API 请求已被限制，将在 \(timeString) 恢复轮询"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "rate-limit-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver rate limit notification: \(error)")
            }
        }
    }

    /// 连续轮询失败时发送通知
    func sendConsecutiveFailureNotification(failures: Int) {
        let content = UNMutableNotificationContent()
        content.title = "GitHub Polling Failed"
        content.body = "连续 \(failures) 次轮询失败，请检查网络或 gh auth 状态"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "consecutive-failure",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to deliver failure notification: \(error)")
            }
        }
    }

    /// Agent 停止运行、需要用户介入时发送通知
    func sendAgentNeedsInterventionNotification(issueNumber: Int, issueTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Agent 需要介入"
        content.body = "Issue #\(issueNumber): \(issueTitle) — Claude Code 已停止，等待你的介入"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "agent-intervention-\(issueNumber)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to send agent intervention notification: \(error.localizedDescription)")
            }
        }
    }

    /// Agent 完成任务（可能已创建 PR）时发送通知
    func sendAgentCompletedNotification(issueNumber: Int, issueTitle: String, prNumber: Int?) {
        let content = UNMutableNotificationContent()
        content.title = "Agent 完成任务"
        content.body = prNumber != nil
            ? "Issue #\(issueNumber): \(issueTitle) — 已创建 PR #\(prNumber!)"
            : "Issue #\(issueNumber): \(issueTitle) — 任务已完成"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "agent-completed-\(issueNumber)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to send agent completed notification: \(error.localizedDescription)")
            }
        }
    }
}
