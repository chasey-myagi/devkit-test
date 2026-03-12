import Testing
import Foundation
@testable import DevKit

@Suite("NotificationService")
struct NotificationServiceTests {
    @Test @MainActor func sharedInstanceExists() {
        let service = NotificationService.shared
        #expect(service != nil)
    }

    @Test @MainActor func sendNotificationDoesNotCrash() {
        NotificationService.shared.sendNewIssueNotification(issueNumber: 123, title: "Test Issue")
        NotificationService.shared.sendStatusChangeNotification(
            issueNumber: 123, oldStatus: "To Do", newStatus: "In Progress"
        )
    }

    @Test @MainActor func sendCIFailureNotificationDoesNotCrash() {
        NotificationService.shared.sendCIFailureNotification(prNumber: 42, title: "Fix bug")
    }

    @Test @MainActor func sendNewReviewNotificationDoesNotCrash() {
        NotificationService.shared.sendNewReviewNotification(prNumber: 42, title: "Feature PR", reviewCount: 3)
    }

    @Test @MainActor func sendRateLimitNotificationDoesNotCrash() {
        let resumeAt = Date.now.addingTimeInterval(900)
        NotificationService.shared.sendRateLimitNotification(resumeAt: resumeAt)
    }
}
