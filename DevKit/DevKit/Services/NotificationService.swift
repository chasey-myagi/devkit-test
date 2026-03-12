import Foundation
import UserNotifications

/// macOS 原生通知服务
/// Phase 1.5: 新 issue assign、状态变更通知
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
                print("DevKit: Notification permission denied")
            }
        } catch {
            print("DevKit: Notification authorization error: \(error)")
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
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("DevKit: Failed to deliver new-issue notification #\(issueNumber): \(error)")
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
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("DevKit: Failed to deliver status-change notification #\(issueNumber): \(error)")
            }
        }
    }
}
