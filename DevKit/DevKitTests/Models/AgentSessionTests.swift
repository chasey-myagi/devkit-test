import Testing
import Foundation
@testable import DevKit

@Suite("AgentSession Tests")
struct AgentSessionTests {
    @Test func initSetsDefaultValues() {
        let session = AgentSession(workspaceName: "test", issueNumber: 42, issueTitle: "Fix bug")
        #expect(session.status == .queued)
        #expect(session.workspaceName == "test")
        #expect(session.issueNumber == 42)
        #expect(session.issueTitle == "Fix bug")
        #expect(session.prNumber == nil)
        #expect(session.startedAt == nil)
    }

    @Test func statusUpdatesSetsUpdatedAt() {
        let session = AgentSession(workspaceName: "test", issueNumber: 1, issueTitle: "Test")
        let before = session.updatedAt
        session.status = .running
        #expect(session.status == .running)
        #expect(session.updatedAt >= before)
    }

    @Test func statusRawRoundTrips() {
        for status in [AgentSessionStatus.queued, .running, .needsIntervention, .intervening, .completed, .failed] {
            let session = AgentSession(workspaceName: "w", issueNumber: 1, issueTitle: "t", status: status)
            #expect(session.status == status)
        }
    }
}
