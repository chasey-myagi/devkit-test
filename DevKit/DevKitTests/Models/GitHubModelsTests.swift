import Testing
import Foundation
@testable import DevKit

@Suite("GitHubModels")
struct GitHubModelsTests {
    @Test func decodesIssueFromGHCLI() throws {
        let json = """
        {
            "number": 8367,
            "title": "[MOI BUG]: 跨页表合并错误",
            "labels": [
                {"name": "kind/bug"},
                {"name": "kind/bug-moi"},
                {"name": "severity/s0"},
                {"name": "customer/中芯国际"}
            ],
            "assignees": [{"login": "endlesschasey-ai"}],
            "milestone": {"title": "MO Intelligence 4.1 迭代"},
            "updatedAt": "2026-03-10T08:30:00Z",
            "body": "附件：https://github.com/user-attachments/assets/abc123"
        }
        """.data(using: .utf8)!
        let issue = try JSONDecoder.ghDecoder.decode(GHIssue.self, from: json)
        #expect(issue.number == 8367)
        #expect(issue.title == "[MOI BUG]: 跨页表合并错误")
        #expect(issue.labels.count == 4)
        #expect(issue.labels[0].name == "kind/bug")
        #expect(issue.assignees[0].login == "endlesschasey-ai")
        #expect(issue.milestone?.title == "MO Intelligence 4.1 迭代")
    }

    @Test func decodesIssueWithNullMilestone() throws {
        let json = """
        {"number": 100, "title": "test", "labels": [], "assignees": [], "milestone": null, "updatedAt": "2026-03-10T08:30:00Z", "body": ""}
        """.data(using: .utf8)!
        let issue = try JSONDecoder.ghDecoder.decode(GHIssue.self, from: json)
        #expect(issue.milestone == nil)
    }

    @Test func extractsAttachmentURLsFromBody() {
        let body = """
        问题描述：表格解析错误
        附件：
        https://github.com/user-attachments/assets/abc123.pdf
        https://github.com/user-attachments/assets/def456.docx
        其他文字
        """
        let urls = GHIssue.extractAttachmentURLs(from: body)
        #expect(urls.count == 2)
        #expect(urls[0].contains("abc123"))
        #expect(urls[1].contains("def456"))
    }
}
