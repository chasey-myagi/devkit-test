import Foundation

enum GitHubCLIError: Error, LocalizedError {
    case invalidRepo(String)
    case mutationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRepo(let repo): return "Invalid repo format: \(repo)"
        case .mutationFailed(let msg): return "Mutation failed: \(msg)"
        }
    }
}

final class GitHubCLIClient: Sendable {
    private let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    func fetchAssignedIssues(repo: String) async throws -> [GHIssue] {
        let jsonFields = "number,title,labels,assignees,milestone,updatedAt,body"
        let output = try await processRunner.run("gh", arguments: [
            "issue", "list",
            "--repo", repo,
            "--assignee", "@me",
            "--state", "open",
            "--limit", "100",
            "--json", jsonFields
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHIssue].self, from: Data(output.utf8))
    }

    func fetchIssueComments(repo: String, issueNumber: Int) async throws -> [GHComment] {
        let output = try await processRunner.run("gh", arguments: [
            "issue", "view", String(issueNumber),
            "--repo", repo,
            "--json", "comments",
            "--jq", ".comments"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHComment].self, from: Data(output.utf8))
    }

    func checkAuthStatus() async throws -> String {
        try await processRunner.run("gh", arguments: ["auth", "status"])
    }

    // MARK: - Project Status

    func fetchProjectStatus(repo: String, issueNumber: Int) async throws -> String {
        let (owner, name) = try splitRepo(repo)

        let query = """
        query($owner: String!, $name: String!, $number: Int!) {
            repository(owner: $owner, name: $name) {
                issue(number: $number) {
                    projectItems(first: 10) {
                        nodes {
                            fieldValueByName(name: "Status") {
                                ... on ProjectV2ItemFieldSingleSelectValue {
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        let output = try await processRunner.run("gh", arguments: [
            "api", "graphql",
            "-F", "owner=\(owner)",
            "-F", "name=\(name)",
            "-F", "number=\(issueNumber)",
            "-f", "query=\(query)"
        ])
        let response = try JSONDecoder.ghDecoder.decode(
            GHGraphQLProjectStatusResponse.self, from: Data(output.utf8)
        )
        let statusName = response.data.repository.issue.projectItems.nodes
            .first?.fieldValueByName?.name
        return statusName ?? "To Do"
    }

    func updateProjectStatus(repo: String, issueNumber: Int, newStatus: String) async throws {
        let (owner, name) = try splitRepo(repo)

        let lookupQuery = """
        query($owner: String!, $name: String!, $number: Int!) {
            repository(owner: $owner, name: $name) {
                issue(number: $number) {
                    projectItems(first: 10) {
                        nodes {
                            id
                            project {
                                id
                                field(name: "Status") {
                                    ... on ProjectV2SingleSelectField {
                                        id
                                        options { id name }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        let lookupOutput = try await processRunner.run("gh", arguments: [
            "api", "graphql",
            "-F", "owner=\(owner)",
            "-F", "name=\(name)",
            "-F", "number=\(issueNumber)",
            "-f", "query=\(lookupQuery)"
        ])
        let lookupData = try JSONDecoder.ghDecoder.decode(
            GHGraphQLProjectLookupResponse.self, from: Data(lookupOutput.utf8)
        )
        guard let node = lookupData.data.repository.issue.projectItems.nodes.first else {
            throw GitHubCLIError.mutationFailed("Issue not in any project")
        }
        let itemId = node.id
        let projectId = node.project.id
        guard let fieldId = node.project.field?.id,
              let optionId = node.project.field?.options?.first(where: { $0.name == newStatus })?.id else {
            throw GitHubCLIError.mutationFailed("Status option '\(newStatus)' not found")
        }

        let mutation = """
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
            updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: { singleSelectOptionId: $optionId }
            }) {
                projectV2Item { id }
            }
        }
        """
        _ = try await processRunner.run("gh", arguments: [
            "api", "graphql",
            "-F", "projectId=\(projectId)",
            "-F", "itemId=\(itemId)",
            "-F", "fieldId=\(fieldId)",
            "-F", "optionId=\(optionId)",
            "-f", "query=\(mutation)"
        ])
    }

    // MARK: - Pull Requests

    func fetchAuthoredPRs(repo: String) async throws -> [GHPullRequest] {
        let jsonFields = "number,title,isDraft,additions,deletions,reviews,statusCheckRollup,updatedAt,body"
        let output = try await processRunner.run("gh", arguments: [
            "pr", "list",
            "--repo", repo,
            "--author", "@me",
            "--state", "open",
            "--limit", "100",
            "--json", jsonFields
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHPullRequest].self, from: Data(output.utf8))
    }

    func fetchPRReviewComments(repo: String, prNumber: Int) async throws -> [GHComment] {
        let output = try await processRunner.run("gh", arguments: [
            "pr", "view", String(prNumber),
            "--repo", repo,
            "--json", "comments",
            "--jq", ".comments"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHComment].self, from: Data(output.utf8))
    }

    // MARK: - PR Merge

    func mergePR(repo: String, prNumber: Int, method: PRMergeMethod) async throws {
        let mergeFlag = switch method {
        case .squash: "--squash"
        case .rebase: "--rebase"
        }
        _ = try await processRunner.run("gh", arguments: [
            "pr", "merge", String(prNumber),
            "--repo", repo,
            mergeFlag,
            "--delete-branch"
        ])
    }

    func checkPRMergeable(repo: String, prNumber: Int) async throws -> PRMergeability {
        let output = try await processRunner.run("gh", arguments: [
            "pr", "view", String(prNumber),
            "--repo", repo,
            "--json", "mergeable,mergeStateStatus"
        ])
        return try JSONDecoder.ghDecoder.decode(PRMergeability.self, from: Data(output.utf8))
    }

    // MARK: - PR Diff

    func fetchPRDiff(repo: String, prNumber: Int) async throws -> String {
        try await processRunner.run("gh", arguments: [
            "pr", "diff", String(prNumber),
            "--repo", repo
        ])
    }

    // MARK: - Actions

    /// 获取 workflow runs 列表
    func fetchWorkflowRuns(repo: String, limit: Int = 30) async throws -> [GHWorkflowRun] {
        let output = try await processRunner.run("gh", arguments: [
            "run", "list",
            "--repo", repo,
            "--limit", String(limit),
            "--json", "databaseId,displayTitle,name,headBranch,status,conclusion,event,createdAt,updatedAt,url"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHWorkflowRun].self, from: Data(output.utf8))
    }

    /// 获取某次 run 的 jobs 列表
    func fetchRunJobs(repo: String, runId: Int) async throws -> [GHWorkflowJob] {
        let output = try await processRunner.run("gh", arguments: [
            "run", "view", String(runId),
            "--repo", repo,
            "--json", "jobs",
            "--jq", ".jobs"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHWorkflowJob].self, from: Data(output.utf8))
    }

    /// 获取某个 job 的日志
    func fetchJobLog(repo: String, jobId: Int) async throws -> String {
        try await processRunner.run("gh", arguments: [
            "run", "view", "--repo", repo,
            "--job", String(jobId),
            "--log"
        ])
    }

    /// 重新运行 workflow（默认仅失败的 jobs）
    @discardableResult
    func rerunWorkflow(repo: String, runId: Int, failedOnly: Bool = true) async throws -> String {
        var args = ["run", "rerun", String(runId), "--repo", repo]
        if failedOnly { args.append("--failed") }
        return try await processRunner.run("gh", arguments: args)
    }

    // MARK: - Issue Create/Edit

    /// 创建新 Issue
    func createIssue(
        repo: String,
        title: String,
        body: String,
        labels: [String] = [],
        assignees: [String] = [],
        milestone: String? = nil
    ) async throws -> GHCreateIssueResult {
        var args = [
            "issue", "create",
            "--repo", repo,
            "--title", title,
            "--body", body,
            "--json", "number,url"
        ]
        for label in labels {
            args += ["--label", label]
        }
        for assignee in assignees {
            args += ["--assignee", assignee]
        }
        if let milestone {
            args += ["--milestone", milestone]
        }
        let output = try await processRunner.run("gh", arguments: args)
        return try JSONDecoder.ghDecoder.decode(GHCreateIssueResult.self, from: Data(output.utf8))
    }

    /// 编辑已有 Issue
    func editIssue(
        repo: String,
        number: Int,
        title: String? = nil,
        body: String? = nil,
        addLabels: [String] = [],
        removeLabels: [String] = []
    ) async throws {
        var args = [
            "issue", "edit", String(number),
            "--repo", repo
        ]
        if let title {
            args += ["--title", title]
        }
        if let body {
            args += ["--body", body]
        }
        if !addLabels.isEmpty {
            args += ["--add-label", addLabels.joined(separator: ",")]
        }
        if !removeLabels.isEmpty {
            args += ["--remove-label", removeLabels.joined(separator: ",")]
        }
        _ = try await processRunner.run("gh", arguments: args)
    }

    /// 获取仓库标签列表
    func fetchRepoLabels(repo: String) async throws -> [GHLabelInfo] {
        let output = try await processRunner.run("gh", arguments: [
            "label", "list",
            "--repo", repo,
            "--json", "name,color",
            "--limit", "100"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHLabelInfo].self, from: Data(output.utf8))
    }

    /// 获取仓库里程碑列表
    func fetchRepoMilestones(repo: String) async throws -> [GHMilestoneInfo] {
        let (owner, name) = try splitRepo(repo)
        let output = try await processRunner.run("gh", arguments: [
            "api", "repos/\(owner)/\(name)/milestones",
            "--jq", "[.[] | {number: .number, title: .title}]"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHMilestoneInfo].self, from: Data(output.utf8))
    }

    // MARK: - Comments

    /// 为 Issue 添加评论
    func addIssueComment(repo: String, number: Int, body: String) async throws {
        _ = try await processRunner.run("gh", arguments: [
            "issue", "comment", String(number),
            "--repo", repo,
            "--body", body
        ])
    }

    /// 为 PR 添加评论
    func addPRComment(repo: String, number: Int, body: String) async throws {
        _ = try await processRunner.run("gh", arguments: [
            "pr", "comment", String(number),
            "--repo", repo,
            "--body", body
        ])
    }

    // MARK: - Private

    private func splitRepo(_ repo: String) throws -> (owner: String, name: String) {
        let parts = repo.split(separator: "/")
        guard parts.count == 2 else { throw GitHubCLIError.invalidRepo(repo) }
        return (String(parts[0]), String(parts[1]))
    }
}
