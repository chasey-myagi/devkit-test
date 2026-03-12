import Foundation

enum PromptTemplateRenderer {
    static func render(
        template: String,
        issueNumber: Int,
        issueTitle: String,
        issueBody: String,
        issueLabels: [String],
        repo: String,
        attachments: [String]
    ) -> String {
        let replacements: [String: String] = [
            "{{number}}": String(issueNumber),
            "{{title}}": issueTitle,
            "{{body}}": issueBody.isEmpty ? "（无）" : issueBody,
            "{{labels}}": issueLabels.isEmpty ? "（无）" : issueLabels.joined(separator: ", "),
            "{{repo}}": repo,
            "{{attachments}}": attachments.isEmpty ? "（无）" : attachments.joined(separator: "\n"),
        ]
        var result = template
        for (placeholder, value) in replacements {
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        return result
    }
}
