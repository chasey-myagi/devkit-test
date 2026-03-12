import Foundation
import SwiftData

enum AgentSessionStatus: String, Codable {
    case queued
    case running
    case needsIntervention
    case intervening
    case completed
    case failed
}

@Model
final class AgentSession {
    #Unique<AgentSession>([\.issueNumber, \.workspaceName])

    var id: UUID
    var workspaceName: String
    var issueNumber: Int
    var issueTitle: String
    var statusRaw: String
    var createdAt: Date
    var startedAt: Date?
    var updatedAt: Date
    var prNumber: Int?

    var status: AgentSessionStatus {
        get { AgentSessionStatus(rawValue: statusRaw) ?? .failed }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    init(
        workspaceName: String,
        issueNumber: Int,
        issueTitle: String,
        status: AgentSessionStatus = .queued
    ) {
        self.id = UUID()
        self.workspaceName = workspaceName
        self.issueNumber = issueNumber
        self.issueTitle = issueTitle
        self.statusRaw = status.rawValue
        self.createdAt = .now
        self.updatedAt = .now
    }
}
