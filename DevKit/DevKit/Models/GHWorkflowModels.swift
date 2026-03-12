import Foundation

/// GitHub Actions workflow run
struct GHWorkflowRun: Codable, Sendable, Identifiable, Hashable {
    var databaseId: Int
    var id: Int { databaseId }
    var displayTitle: String
    var name: String              // workflow 名称
    var headBranch: String
    var status: String            // "completed", "in_progress", "queued"
    var conclusion: String?       // "success", "failure", "cancelled"
    var event: String             // "push", "pull_request"
    var createdAt: String
    var updatedAt: String
    var url: String

    /// 根据 status + conclusion 返回对应的 SF Symbol
    var statusIcon: String {
        switch status {
        case "completed":
            switch conclusion {
            case "success": return "checkmark.circle.fill"
            case "failure": return "xmark.circle.fill"
            case "cancelled": return "slash.circle.fill"
            default: return "questionmark.circle"
            }
        case "in_progress": return "circle.dotted.circle"
        case "queued": return "clock.circle"
        default: return "questionmark.circle"
        }
    }

    // Hashable 仅通过 databaseId 比较
    static func == (lhs: GHWorkflowRun, rhs: GHWorkflowRun) -> Bool {
        lhs.databaseId == rhs.databaseId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(databaseId)
    }
}

/// GitHub Actions workflow job
struct GHWorkflowJob: Codable, Sendable, Identifiable {
    var id: Int
    var name: String
    var status: String
    var conclusion: String?
    var startedAt: String?
    var completedAt: String?

    /// job 状态图标
    var statusIcon: String {
        switch status {
        case "completed":
            switch conclusion {
            case "success": return "checkmark.circle.fill"
            case "failure": return "xmark.circle.fill"
            case "cancelled": return "slash.circle.fill"
            case "skipped": return "forward.circle"
            default: return "questionmark.circle"
            }
        case "in_progress": return "circle.dotted.circle"
        case "queued": return "clock.circle"
        default: return "questionmark.circle"
        }
    }
}
