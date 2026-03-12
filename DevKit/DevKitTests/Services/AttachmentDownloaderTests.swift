import Testing
import Foundation
@testable import DevKit

@Suite("AttachmentDownloader")
struct AttachmentDownloaderTests {

    @Test @MainActor func downloadSuccessCreatesCorrectCurlCommands() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "curl", output: "")
        let downloader = AttachmentDownloader(processRunner: mock)

        let urls = [
            "https://github.com/user-attachments/assets/image1.png",
            "https://github.com/user-attachments/assets/doc.pdf"
        ]

        let results = await downloader.downloadAttachments(
            urls: urls,
            localPath: "/tmp/test-repo",
            issueNumber: 3
        )

        #expect(results.count == 2)
        #expect(results[0].error == nil)
        #expect(results[0].localPath == "/tmp/test-repo/issues/3/image1.png")
        #expect(results[1].error == nil)
        #expect(results[1].localPath == "/tmp/test-repo/issues/3/doc.pdf")

        // curl 命令应该被调用两次
        #expect(mock.recordedCommands.count == 2)

        // 验证第一个 curl 命令格式
        let firstCmd = mock.recordedCommands[0]
        #expect(firstCmd.executable == "curl")
        #expect(firstCmd.arguments == ["-L", "-o", "/tmp/test-repo/issues/3/image1.png", "https://github.com/user-attachments/assets/image1.png"])

        // 验证第二个 curl 命令格式
        let secondCmd = mock.recordedCommands[1]
        #expect(secondCmd.executable == "curl")
        #expect(secondCmd.arguments == ["-L", "-o", "/tmp/test-repo/issues/3/doc.pdf", "https://github.com/user-attachments/assets/doc.pdf"])
    }

    @Test @MainActor func downloadFailureReturnsError() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(for: "curl", error: ProcessRunnerError.executionFailed(
            terminationStatus: 1, stderr: "Connection refused"
        ))
        let downloader = AttachmentDownloader(processRunner: mock)

        let results = await downloader.downloadAttachments(
            urls: ["https://github.com/user-attachments/assets/fail.png"],
            localPath: "/tmp/test-repo",
            issueNumber: 5
        )

        #expect(results.count == 1)
        #expect(results[0].localPath == nil)
        #expect(results[0].error != nil)
        #expect(results[0].url == "https://github.com/user-attachments/assets/fail.png")
    }

    @Test @MainActor func emptyURLsReturnsEmptyResults() async throws {
        let mock = MockProcessRunner()
        let downloader = AttachmentDownloader(processRunner: mock)

        let results = await downloader.downloadAttachments(
            urls: [],
            localPath: "/tmp/test-repo",
            issueNumber: 1
        )

        #expect(results.isEmpty)
        #expect(mock.recordedCommands.isEmpty)
    }

    @Test @MainActor func partialFailureReportsCorrectResults() async throws {
        let mock = MockProcessRunner()
        // 第一个成功，第二个失败
        mock.stubbedResults["curl -L -o /tmp/repo/issues/7/good.png https://example.com/good.png"] = .success("")
        mock.stubbedResults["curl -L -o /tmp/repo/issues/7/bad.png https://example.com/bad.png"] = .failure(
            ProcessRunnerError.executionFailed(terminationStatus: 22, stderr: "404 Not Found")
        )
        let downloader = AttachmentDownloader(processRunner: mock)

        let results = await downloader.downloadAttachments(
            urls: ["https://example.com/good.png", "https://example.com/bad.png"],
            localPath: "/tmp/repo",
            issueNumber: 7
        )

        #expect(results.count == 2)
        #expect(results[0].error == nil)
        #expect(results[0].localPath == "/tmp/repo/issues/7/good.png")
        #expect(results[1].error != nil)
        #expect(results[1].localPath == nil)
    }

    @Test @MainActor func directoryStructureUsesIssueNumber() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "curl", output: "")
        let downloader = AttachmentDownloader(processRunner: mock)

        let tmpDir = NSTemporaryDirectory() + "devkit-test-\(UUID().uuidString)"
        let results = await downloader.downloadAttachments(
            urls: ["https://example.com/file.txt"],
            localPath: tmpDir,
            issueNumber: 42
        )

        #expect(results.count == 1)
        #expect(results[0].localPath == "\(tmpDir)/issues/42/file.txt")

        // 清理
        try? FileManager.default.removeItem(atPath: tmpDir)
    }
}
