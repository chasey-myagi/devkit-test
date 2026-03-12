import Foundation

struct GHIssue: Codable, Sendable {
    var number: Int
    var title: String
    var labels: [GHLabel]
    var assignees: [GHUser]
    var milestone: GHMilestone?
    var updatedAt: String
    var body: String?

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

extension JSONDecoder {
    static let ghDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
}
