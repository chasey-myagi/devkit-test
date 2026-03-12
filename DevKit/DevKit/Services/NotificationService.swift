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
}
