import Testing
import Foundation
@testable import DevKit

@Suite("CachedPR")
struct CachedPRTests {

    // MARK: - boardColumn mapping

    @Test func draftPRReturnsDraftColumn() {
        let pr = CachedPR(
            number: 1, title: "WIP feature",
            isDraft: true,
            reviewState: "APPROVED", checksStatus: "SUCCESS",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "Draft")
    }

    @Test func draftTakesPriorityOverAll() {
        let pr = CachedPR(
            number: 2, title: "Draft with changes requested",
            isDraft: true,
            reviewState: "CHANGES_REQUESTED", checksStatus: "FAILURE",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "Draft")
    }

    @Test func changesRequestedReturnsNeedFix() {
        let pr = CachedPR(
            number: 3, title: "Needs changes",
            isDraft: false,
            reviewState: "CHANGES_REQUESTED", checksStatus: "SUCCESS",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "Need Fix")
    }

    @Test func approvedWithSuccessReturnsReady() {
        let pr = CachedPR(
            number: 4, title: "Ready to merge",
            isDraft: false,
            reviewState: "APPROVED", checksStatus: "SUCCESS",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "Ready")
    }

    @Test func approvedWithFailureReturnsInReview() {
        let pr = CachedPR(
            number: 5, title: "Approved but CI failed",
            isDraft: false,
            reviewState: "APPROVED", checksStatus: "FAILURE",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "In Review")
    }

    @Test func pendingReviewReturnsInReview() {
        let pr = CachedPR(
            number: 6, title: "Waiting for review",
            isDraft: false,
            reviewState: "PENDING", checksStatus: "PENDING",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "In Review")
    }

    @Test func approvedWithPendingChecksReturnsInReview() {
        let pr = CachedPR(
            number: 7, title: "Approved but CI pending",
            isDraft: false,
            reviewState: "APPROVED", checksStatus: "PENDING",
            workspaceName: "test"
        )
        #expect(pr.boardColumn == "In Review")
    }

    // MARK: - linkedIssueNumbers JSON round-trip

    @Test func linkedIssueNumbersRoundTrip() {
        let pr = CachedPR(
            number: 10, title: "Linked PR",
            linkedIssueNumbers: [42, 99, 100],
            workspaceName: "test"
        )
        #expect(pr.linkedIssueNumbers == [42, 99, 100])
    }

    @Test func emptyLinkedIssueNumbers() {
        let pr = CachedPR(number: 11, title: "No links", workspaceName: "test")
        #expect(pr.linkedIssueNumbers.isEmpty)
    }

    @Test func setLinkedIssueNumbers() {
        let pr = CachedPR(number: 12, title: "Set links", workspaceName: "test")
        pr.linkedIssueNumbers = [1, 2, 3]
        #expect(pr.linkedIssueNumbers == [1, 2, 3])
        pr.linkedIssueNumbers = []
        #expect(pr.linkedIssueNumbers.isEmpty)
    }

    @Test func malformedRawReturnsEmptyArray() {
        let pr = CachedPR(number: 13, title: "Bad raw", workspaceName: "test")
        pr.linkedIssueNumbersRaw = "not json"
        #expect(pr.linkedIssueNumbers.isEmpty)
    }
}
