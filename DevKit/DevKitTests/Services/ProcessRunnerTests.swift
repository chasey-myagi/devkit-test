import Testing
import Foundation
@testable import DevKit

@Suite("ProcessRunner")
struct ProcessRunnerTests {
    @Test func mockRunnerRecordsCommands() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "echo", output: "hello")
        let result = try await mock.run("echo", arguments: ["hello"])
        #expect(result == "hello")
        #expect(mock.recordedCommands.count == 1)
        #expect(mock.recordedCommands[0].executable == "echo")
    }

    @Test func mockRunnerThrowsOnUnstubbed() async {
        let mock = MockProcessRunner()
        await #expect(throws: ProcessRunnerError.self) {
            try await mock.run("unknown", arguments: [])
        }
    }

    // MARK: - isRateLimited

    @Test func isRateLimitedDetectsRateLimitInStderr() {
        let error = ProcessRunnerError.executionFailed(
            terminationStatus: 1,
            stderr: "HTTP 403: API rate limit exceeded for user"
        )
        #expect(error.isRateLimited == true)
    }

    @Test func isRateLimitedDetects403InStderr() {
        let error = ProcessRunnerError.executionFailed(
            terminationStatus: 1,
            stderr: "gh: 403 Forbidden"
        )
        #expect(error.isRateLimited == true)
    }

    @Test func isRateLimitedReturnsFalseForOtherErrors() {
        let error = ProcessRunnerError.executionFailed(
            terminationStatus: 1,
            stderr: "network timeout"
        )
        #expect(error.isRateLimited == false)
    }

    @Test func isRateLimitedReturnsFalseForNotFound() {
        let error = ProcessRunnerError.notFound("gh")
        #expect(error.isRateLimited == false)
    }

    @Test func isRateLimitedIsCaseInsensitive() {
        let error = ProcessRunnerError.executionFailed(
            terminationStatus: 1,
            stderr: "Rate Limit exceeded"
        )
        #expect(error.isRateLimited == true)
    }
}
