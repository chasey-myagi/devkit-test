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

    @Test func decodesPRMergeability() throws {
        let json = """
        {"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN"}
        """.data(using: .utf8)!
        let result = try JSONDecoder.ghDecoder.decode(PRMergeability.self, from: json)
        #expect(result.mergeable == "MERGEABLE")
        #expect(result.mergeStateStatus == "CLEAN")
        #expect(result.canMerge == true)
        #expect(result.reasonText.isEmpty)
    }

    @Test func mergeabilityConflicting() {
        let m = PRMergeability(mergeable: "CONFLICTING", mergeStateStatus: "DIRTY")
        #expect(m.canMerge == false)
        #expect(m.reasonText == "Has merge conflicts")
    }

    @Test func mergeabilityBlocked() {
        let m = PRMergeability(mergeable: "MERGEABLE", mergeStateStatus: "BLOCKED")
        #expect(m.canMerge == false)
        #expect(m.reasonText == "Merge blocked by branch protection")
    }

    @Test func mergeabilityUnstableCanMerge() {
        let m = PRMergeability(mergeable: "MERGEABLE", mergeStateStatus: "UNSTABLE")
        #expect(m.canMerge == true)
    }

    @Test func mergeabilityUnknown() {
        let m = PRMergeability(mergeable: "UNKNOWN", mergeStateStatus: "CLEAN")
        #expect(m.canMerge == false)
        #expect(m.reasonText == "Mergeability unknown, try again")
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
