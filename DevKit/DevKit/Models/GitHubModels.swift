import Foundation

struct GHIssue: Codable, Sendable {
    var number: Int
    var title: String
    var labels: [GHLabel]
    var assignees: [GHUser]
    var milestone: GHMilestone?
    var updatedAt: String
    var body: String?

    var parsedUpdatedAt: Date {
        GHDateParser.parse(updatedAt) ?? .now
    }

    static func extractAttachmentURLs(from body: String?) -> [String] {
        guard let body else { return [] }
        let pattern = #"https://github\.com/user-attachments/assets/[^\s\)\]\"']+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(body.startIndex..., in: body)
        return regex.matches(in: body, range: range).compactMap { match in
            Range(match.range, in: body).map { String(body[$0]) }
        }
    }
}

struct GHLabel: Codable, Sendable {
    var name: String
}

struct GHUser: Codable, Sendable {
    var login: String
}

struct GHMilestone: Codable, Sendable {
    var title: String
}

struct GHProjectItem: Codable, Sendable {
    var status: GHProjectStatus?

    struct GHProjectStatus: Codable, Sendable {
        var name: String
    }
}

struct GHComment: Codable, Sendable, Identifiable {
    var id: Int
    var body: String
    var author: GHUser
    var createdAt: String

    var createdDate: Date? {
        GHDateParser.parse(createdAt)
    }
}

struct GHGraphQLProjectStatusResponse: Codable, Sendable {
    var data: GHGraphQLData
    struct GHGraphQLData: Codable, Sendable {
        var repository: GHGraphQLRepository
    }
    struct GHGraphQLRepository: Codable, Sendable {
        var issue: GHGraphQLIssue
    }
    struct GHGraphQLIssue: Codable, Sendable {
        var projectItems: GHGraphQLProjectItems
    }
    struct GHGraphQLProjectItems: Codable, Sendable {
        var nodes: [GHGraphQLProjectNode]
    }
    struct GHGraphQLProjectNode: Codable, Sendable {
        var fieldValueByName: GHGraphQLFieldValue?
    }
    struct GHGraphQLFieldValue: Codable, Sendable {
        var name: String
    }
}

struct GHGraphQLProjectLookupResponse: Codable, Sendable {
    var data: DataField
    struct DataField: Codable, Sendable { var repository: Repo }
    struct Repo: Codable, Sendable { var issue: IssueField }
    struct IssueField: Codable, Sendable { var projectItems: ProjectItems }
    struct ProjectItems: Codable, Sendable { var nodes: [Node] }
    struct Node: Codable, Sendable { var id: String; var project: Project }
    struct Project: Codable, Sendable { var id: String; var field: Field? }
    struct Field: Codable, Sendable { var id: String; var options: [Option]? }
    struct Option: Codable, Sendable { var id: String; var name: String }
}

// MARK: - Issue Create/Edit Models

struct GHCreateIssueResult: Decodable, Sendable {
    let number: Int
    let url: String
}

struct GHLabelInfo: Decodable, Sendable, Identifiable {
    let name: String
    let color: String
    var id: String { name }
}

struct GHMilestoneInfo: Decodable, Sendable, Identifiable {
    let number: Int
    let title: String
    var id: Int { number }
}

// MARK: - Pull Request Models

struct GHPullRequest: Codable, Sendable {
    var number: Int
    var title: String
    var isDraft: Bool
    var additions: Int
    var deletions: Int
    var reviews: [GHReview]
    var statusCheckRollup: [GHStatusCheck]
    var updatedAt: String
    var body: String?

    /// 从 body 提取关联的 issue 号（#123, closes #456 等）
    static func extractLinkedIssues(from body: String?) -> [Int] {
        guard let body else { return [] }
        let pattern = #"(?:closes?|fixes?|resolves?)\s+#(\d+)|#(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let range = NSRange(body.startIndex..., in: body)
        var numbers = Set<Int>()
        regex.enumerateMatches(in: body, range: range) { match, _, _ in
            guard let match else { return }
            for i in 1..<match.numberOfRanges {
                if let range = Range(match.range(at: i), in: body), let num = Int(body[range]) {
                    numbers.insert(num)
                }
            }
        }
        return Array(numbers).sorted()
    }

    /// 综合 review 状态
    var aggregatedReviewState: String {
        if reviews.contains(where: { $0.state == "CHANGES_REQUESTED" }) { return "CHANGES_REQUESTED" }
        if reviews.contains(where: { $0.state == "APPROVED" }) { return "APPROVED" }
        return "PENDING"
    }

    /// Review 数量
    var reviewCount: Int {
        reviews.count
    }

    /// 综合 CI 状态
    var aggregatedChecksStatus: String {
        if statusCheckRollup.isEmpty { return "PENDING" }
        if statusCheckRollup.allSatisfy({ $0.status == "COMPLETED" && $0.conclusion == "SUCCESS" }) { return "SUCCESS" }
        if statusCheckRollup.contains(where: { $0.conclusion == "FAILURE" }) { return "FAILURE" }
        return "PENDING"
    }
}

struct GHReview: Codable, Sendable {
    var state: String  // "APPROVED", "CHANGES_REQUESTED", "COMMENTED"
    var author: GHUser
}

struct GHStatusCheck: Codable, Sendable {
    var context: String
    var status: String       // "COMPLETED", "IN_PROGRESS", "QUEUED"
    var conclusion: String?  // "SUCCESS", "FAILURE", "NEUTRAL"

    enum CodingKeys: String, CodingKey {
        case context, status, conclusion
    }

    init(context: String = "", status: String = "PENDING", conclusion: String? = nil) {
        self.context = context
        self.status = status
        self.conclusion = conclusion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = (try? container.decode(String.self, forKey: .context)) ?? ""
        status = (try? container.decode(String.self, forKey: .status)) ?? "PENDING"
        conclusion = try? container.decode(String.self, forKey: .conclusion)
    }
}

// MARK: - PR Merge Models

enum PRMergeMethod: String, Sendable {
    case squash, rebase
}

struct PRMergeability: Codable, Sendable {
    var mergeable: String       // "MERGEABLE", "CONFLICTING", "UNKNOWN"
    var mergeStateStatus: String // "CLEAN", "DIRTY", "BLOCKED", "UNSTABLE"

    var canMerge: Bool {
        mergeable == "MERGEABLE" && (mergeStateStatus == "CLEAN" || mergeStateStatus == "UNSTABLE")
    }

    var reasonText: String {
        if mergeable == "CONFLICTING" { return "Has merge conflicts" }
        if mergeStateStatus == "BLOCKED" { return "Merge blocked by branch protection" }
        if mergeStateStatus == "DIRTY" { return "Required checks have not passed" }
        if mergeable == "UNKNOWN" { return "Mergeability unknown, try again" }
        return ""
    }
}

extension JSONDecoder {
    static let ghDecoder = JSONDecoder()
}

enum GHDateParser {
    private nonisolated(unsafe) static let fracFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private nonisolated(unsafe) static let noFracFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ string: String) -> Date? {
        fracFormatter.date(from: string) ?? noFracFormatter.date(from: string)
    }
}
