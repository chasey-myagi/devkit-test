import Testing
import Foundation
@testable import DevKit

@Suite("AgentNotifyServer Tests")
struct AgentNotifyServerTests {
    @Test func parsesStopEvent() {
        let body = Data("""
        {"session_id":"abc-123","hook_event_name":"Stop"}
        """.utf8)
        let event = AgentNotifyServer.parseEvent(from: body, path: "/agent/abc-123/stop")
        #expect(event?.sessionID == "abc-123")
        #expect(event?.type == .stop)
    }

    @Test func parsesNotificationEvent() {
        let body = Data("""
        {"session_id":"def-456","hook_event_name":"Notification"}
        """.utf8)
        let event = AgentNotifyServer.parseEvent(from: body, path: "/agent/def-456/notification")
        #expect(event?.sessionID == "def-456")
        #expect(event?.type == .notification)
    }

    @Test func rejectsInvalidPath() {
        let body = Data("{}".utf8)
        let event = AgentNotifyServer.parseEvent(from: body, path: "/invalid")
        #expect(event == nil)
    }

    @Test func extractsSessionIDFromPath() {
        let id = AgentNotifyServer.extractSessionID(from: "/agent/550e8400-e29b-41d4/stop")
        #expect(id == "550e8400-e29b-41d4")
    }
}
