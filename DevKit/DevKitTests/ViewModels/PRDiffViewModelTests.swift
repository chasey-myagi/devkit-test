import Testing
import Foundation
@testable import DevKit

@Suite("PRDiffViewModel")
struct PRDiffViewModelTests {

    @Test @MainActor func loadDiffSuccess() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        diff --git a/f.swift b/f.swift
        --- a/f.swift
        +++ b/f.swift
        @@ -1,1 +1,2 @@
         line1
        +line2
        """)
        let vm = PRDiffViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadDiff(repo: "owner/repo", prNumber: 1)

        #expect(vm.files.count == 1)
        #expect(vm.files[0].additions == 1)
        #expect(vm.files[0].deletions == 0)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func loadDiffMultipleFiles() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        diff --git a/a.swift b/a.swift
        --- a/a.swift
        +++ b/a.swift
        @@ -1,2 +1,3 @@
         line1
        +added
         line2
        diff --git a/b.swift b/b.swift
        --- a/b.swift
        +++ b/b.swift
        @@ -1,3 +1,2 @@
         line1
        -removed
         line3
        """)
        let vm = PRDiffViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadDiff(repo: "owner/repo", prNumber: 2)

        #expect(vm.files.count == 2)
        #expect(vm.files[0].newPath == "a.swift")
        #expect(vm.files[1].newPath == "b.swift")
        #expect(vm.error == nil)
    }

    @Test @MainActor func loadDiffError() async {
        let mock = MockProcessRunner()
        // 不设 stub -> 抛出 notFound 错误
        let vm = PRDiffViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadDiff(repo: "owner/repo", prNumber: 1)

        #expect(vm.files.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func loadDiffEmptyOutput() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let vm = PRDiffViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadDiff(repo: "owner/repo", prNumber: 1)

        #expect(vm.files.isEmpty)
        #expect(vm.error == nil)
    }

    @Test @MainActor func loadDiffClearsOldError() async {
        let mock = MockProcessRunner()
        // 第一次失败
        let vm = PRDiffViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadDiff(repo: "owner/repo", prNumber: 1)
        #expect(vm.error != nil)

        // 第二次成功
        mock.stubSuccess(for: "gh", output: """
        diff --git a/f.swift b/f.swift
        --- a/f.swift
        +++ b/f.swift
        @@ -1,1 +1,2 @@
         line1
        +line2
        """)
        await vm.loadDiff(repo: "owner/repo", prNumber: 1)
        #expect(vm.error == nil)
        #expect(vm.files.count == 1)
    }
}
