import Foundation
import SwiftData

@Model
final class CachedPR {
    #Unique<CachedPR>([\.number, \.workspaceName])

    var number: Int
    var title: String
    var isDraft: Bool
    var additions: Int
    var deletions: Int
    var reviewState: String       // "APPROVED", "CHANGES_REQUESTED", "PENDING"
    var checksStatus: String      // "SUCCESS", "FAILURE", "PENDING"
    var linkedIssueNumbersRaw: String
    var updatedAt: Date
    var workspaceName: String

    var linkedIssueNumbers: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: Data(linkedIssueNumbersRaw.utf8))) ?? [] }
        set { linkedIssueNumbersRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    /// 根据映射规则计算看板列
    var boardColumn: String {
        if isDraft { return "Draft" }
        if reviewState == "CHANGES_REQUESTED" { return "Need Fix" }
        if reviewState == "APPROVED" && checksStatus == "SUCCESS" { return "Ready" }
        return "In Review"
    }

    init(
        number: Int,
        title: String,
        isDraft: Bool = false,
        additions: Int = 0,
        deletions: Int = 0,
        reviewState: String = "PENDING",
        checksStatus: String = "PENDING",
        linkedIssueNumbers: [Int] = [],
        updatedAt: Date = .now,
        workspaceName: String
    ) {
        self.number = number
        self.title = title
        self.isDraft = isDraft
        self.additions = additions
        self.deletions = deletions
        self.reviewState = reviewState
        self.checksStatus = checksStatus
        self.linkedIssueNumbersRaw = (try? String(data: JSONEncoder().encode(linkedIssueNumbers), encoding: .utf8)) ?? "[]"
        self.updatedAt = updatedAt
        self.workspaceName = workspaceName
    }
}
