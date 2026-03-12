import Testing
import Foundation
@testable import DevKit

@Suite("CachedIssue")
struct CachedIssueTests {

    @Test func linkedPRNumbersRoundTrip() {
        let issue = CachedIssue(
            number: 1,
            title: "Test",
            linkedPRNumbers: [4, 5],
            workspaceName: "test"
        )
        #expect(issue.linkedPRNumbers == [4, 5])
    }

    @Test func emptyLinkedPRNumbers() {
        let issue = CachedIssue(number: 2, title: "Test", workspaceName: "test")
        #expect(issue.linkedPRNumbers.isEmpty)
    }

    @Test func setLinkedPRNumbers() {
        let issue = CachedIssue(number: 3, title: "Test", workspaceName: "test")
        issue.linkedPRNumbers = [10, 20]
        #expect(issue.linkedPRNumbers == [10, 20])
        issue.linkedPRNumbers = []
        #expect(issue.linkedPRNumbers.isEmpty)
    }

    @Test func malformedLinkedPRNumbersRawReturnsEmpty() {
        let issue = CachedIssue(number: 4, title: "Test", workspaceName: "test")
        issue.linkedPRNumbersRaw = "bad json"
        #expect(issue.linkedPRNumbers.isEmpty)
    }

    @Test func labelsRoundTrip() {
        let issue = CachedIssue(
            number: 5,
            title: "Labels test",
            labels: ["bug", "p0"],
            workspaceName: "test"
        )
        #expect(issue.labels == ["bug", "p0"])
    }

    @Test func assigneesRoundTrip() {
        let issue = CachedIssue(
            number: 6,
            title: "Assignees test",
            assignees: ["user1", "user2"],
            workspaceName: "test"
        )
        #expect(issue.assignees == ["user1", "user2"])
    }

    @Test func attachmentURLsRoundTrip() {
        let issue = CachedIssue(
            number: 7,
            title: "Attachments test",
            attachmentURLs: ["https://example.com/a.png"],
            workspaceName: "test"
        )
        #expect(issue.attachmentURLs == ["https://example.com/a.png"])
    }
}
