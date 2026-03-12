import Testing
@testable import DevKit

@Suite("PromptTemplateRenderer Tests")
struct PromptTemplateRendererTests {
    @Test func rendersAllPlaceholders() {
        let template = "Issue #{{number}}: {{title}}\n{{body}}\nLabels: {{labels}}\nRepo: {{repo}}\nAttachments: {{attachments}}"
        let result = PromptTemplateRenderer.render(
            template: template,
            issueNumber: 42,
            issueTitle: "Fix login",
            issueBody: "Login is broken",
            issueLabels: ["bug", "critical"],
            repo: "owner/repo",
            attachments: ["/tmp/screenshot.png"]
        )
        #expect(result.contains("Issue #42: Fix login"))
        #expect(result.contains("Login is broken"))
        #expect(result.contains("bug, critical"))
        #expect(result.contains("owner/repo"))
        #expect(result.contains("/tmp/screenshot.png"))
    }

    @Test func handlesEmptyOptionalFields() {
        let template = "{{number}} {{labels}} {{attachments}}"
        let result = PromptTemplateRenderer.render(
            template: template,
            issueNumber: 1,
            issueTitle: "",
            issueBody: "",
            issueLabels: [],
            repo: "o/r",
            attachments: []
        )
        #expect(result.contains("1"))
        #expect(result.contains("（无）"))
    }

    @Test func preservesUnknownPlaceholders() {
        let template = "{{number}} {{unknown}}"
        let result = PromptTemplateRenderer.render(
            template: template,
            issueNumber: 5,
            issueTitle: "",
            issueBody: "",
            issueLabels: [],
            repo: "o/r",
            attachments: []
        )
        #expect(result.contains("{{unknown}}"))
    }
}
