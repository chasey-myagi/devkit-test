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
}
