import Foundation
import SwiftData

@Model
final class Workspace {
    var name: String
    var repoFullName: String
    var localPath: String
    var pollingIntervalSeconds: Int
    var maxConcurrency: Int
    var isActive: Bool
    var agentPromptTemplate: String

    init(
        name: String,
        repoFullName: String,
        localPath: String,
        pollingIntervalSeconds: Int = 1800,
        maxConcurrency: Int = 2,
        isActive: Bool = false,
        agentPromptTemplate: String = """
请解决以下 GitHub Issue：

## Issue #{{number}}: {{title}}

{{body}}

### 标签
{{labels}}

### 仓库
{{repo}}

请使用 /devkit-solve-issue skill 作为工作流程指导。
"""
    ) {
        self.name = name
        self.repoFullName = repoFullName
        self.localPath = localPath
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.maxConcurrency = maxConcurrency
        self.isActive = isActive
        self.agentPromptTemplate = agentPromptTemplate
    }
}
