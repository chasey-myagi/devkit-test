import Foundation

struct AgentWorkspaceConfigurator {
    let port: UInt16

    func ensureHookConfig(at workspacePath: String) throws {
        let claudeDir = "\(workspacePath)/.claude"
        let fm = FileManager.default
        try fm.createDirectory(atPath: claudeDir, withIntermediateDirectories: true)

        let settingsPath = "\(claudeDir)/settings.local.json"
        var existing: [String: Any] = [:]
        if let data = fm.contents(atPath: settingsPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            existing = json
        }

        let hookTemplate: [String: Any] = [
            "Stop": [["matcher": "", "hooks": [["type": "http", "url": "http://localhost:\(port)/agent/${CLAUDE_SESSION_ID}/stop", "timeout": 5]]]],
            "Notification": [["matcher": "", "hooks": [["type": "http", "url": "http://localhost:\(port)/agent/${CLAUDE_SESSION_ID}/notification", "timeout": 5]]]]
        ]
        existing["hooks"] = hookTemplate

        let data = try JSONSerialization.data(withJSONObject: existing, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: settingsPath))
    }

    func ensureSkill(at workspacePath: String, content: String) throws {
        let skillDir = "\(workspacePath)/.claude/skills/devkit-solve-issue"
        try FileManager.default.createDirectory(atPath: skillDir, withIntermediateDirectories: true)

        let skillContent = """
---
name: devkit-solve-issue
description: 自动解决 GitHub Issue 的标准流程
user-invocable: true
---

\(content)
"""
        try skillContent.write(toFile: "\(skillDir)/SKILL.md", atomically: true, encoding: .utf8)
    }
}
