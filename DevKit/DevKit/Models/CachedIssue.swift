import Foundation
import SwiftData

@Model
final class CachedIssue {
    #Unique<CachedIssue>([\.number, \.workspaceName])

    var number: Int
    var title: String
    var labelsRaw: String
    var severity: String?
    var priority: String?
    var customer: String?
    var projectStatus: String
    var assigneesRaw: String
    var milestone: String?
    var attachmentURLsRaw: String
    var bodyHTML: String?
    var linkedPRNumbersRaw: String
    var updatedAt: Date
    var workspaceName: String
    var attachmentStatus: String = "none"  // none / downloading / downloaded / failed

    var labels: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(labelsRaw.utf8))) ?? [] }
        set { labelsRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var assignees: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(assigneesRaw.utf8))) ?? [] }
        set { assigneesRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var attachmentURLs: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(attachmentURLsRaw.utf8))) ?? [] }
        set { attachmentURLsRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var linkedPRNumbers: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: Data(linkedPRNumbersRaw.utf8))) ?? [] }
        set { linkedPRNumbersRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    init(
        number: Int,
        title: String,
        labels: [String] = [],
        severity: String? = nil,
        priority: String? = nil,
        customer: String? = nil,
        projectStatus: String = "To Do",
        assignees: [String] = [],
        milestone: String? = nil,
        attachmentURLs: [String] = [],
        bodyHTML: String? = nil,
        linkedPRNumbers: [Int] = [],
        updatedAt: Date = .now,
        workspaceName: String
    ) {
        self.number = number
        self.title = title
        self.labelsRaw = (try? String(data: JSONEncoder().encode(labels), encoding: .utf8)) ?? "[]"
        self.severity = severity
        self.priority = priority
        self.customer = customer
        self.projectStatus = projectStatus
        self.assigneesRaw = (try? String(data: JSONEncoder().encode(assignees), encoding: .utf8)) ?? "[]"
        self.milestone = milestone
        self.attachmentURLsRaw = (try? String(data: JSONEncoder().encode(attachmentURLs), encoding: .utf8)) ?? "[]"
        self.bodyHTML = bodyHTML
        self.linkedPRNumbersRaw = (try? String(data: JSONEncoder().encode(linkedPRNumbers), encoding: .utf8)) ?? "[]"
        self.updatedAt = updatedAt
        self.workspaceName = workspaceName
    }
}
