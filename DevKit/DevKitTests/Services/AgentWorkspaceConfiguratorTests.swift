import Testing
import Foundation
@testable import DevKit

@Suite("AgentWorkspaceConfigurator Tests")
struct AgentWorkspaceConfiguratorTests {
    let tempDir: String

    init() throws {
        tempDir = NSTemporaryDirectory() + "devkit-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    @Test func writesHookSettings() throws {
        let configurator = AgentWorkspaceConfigurator(port: 19836)
        try configurator.ensureHookConfig(at: tempDir)
        let path = "\(tempDir)/.claude/settings.local.json"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let hooks = json["hooks"] as! [String: Any]
        #expect(hooks["Stop"] != nil)
        #expect(hooks["Notification"] != nil)
    }

    @Test func mergesExistingSettings() throws {
        let claudeDir = "\(tempDir)/.claude"
        try FileManager.default.createDirectory(atPath: claudeDir, withIntermediateDirectories: true)
        let existing: [String: Any] = ["customKey": "customValue"]
        let data = try JSONSerialization.data(withJSONObject: existing)
        try data.write(to: URL(fileURLWithPath: "\(claudeDir)/settings.local.json"))

        let configurator = AgentWorkspaceConfigurator(port: 19836)
        try configurator.ensureHookConfig(at: tempDir)

        let updated = try Data(contentsOf: URL(fileURLWithPath: "\(claudeDir)/settings.local.json"))
        let json = try JSONSerialization.jsonObject(with: updated) as! [String: Any]
        #expect(json["customKey"] as? String == "customValue")
        #expect(json["hooks"] != nil)
    }

    @Test func writesSkillFile() throws {
        let configurator = AgentWorkspaceConfigurator(port: 19836)
        let skillContent = "## SOP\n1. Fix the bug"
        try configurator.ensureSkill(at: tempDir, content: skillContent)
        let path = "\(tempDir)/.claude/skills/devkit-solve-issue/SKILL.md"
        let content = try String(contentsOfFile: path, encoding: .utf8)
        #expect(content.contains("devkit-solve-issue"))
        #expect(content.contains("Fix the bug"))
    }
}
