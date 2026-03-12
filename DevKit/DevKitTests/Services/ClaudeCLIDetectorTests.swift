import Testing
@testable import DevKit

@Suite("ClaudeCLIDetector Tests")
struct ClaudeCLIDetectorTests {
    @Test func detectsWithMockRunner() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "which", output: "/usr/local/bin/claude\n")
        let detector = ClaudeCLIDetector(processRunner: mock)
        let result = await detector.detect()
        #expect(result.isInstalled)
        #expect(result.path == "/usr/local/bin/claude")
    }

    @Test func detectsNotInstalled() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(for: "which", error: ProcessRunnerError.executionFailed(terminationStatus: 1, stderr: ""))
        let detector = ClaudeCLIDetector(processRunner: mock)
        let result = await detector.detect()
        #expect(!result.isInstalled)
        #expect(result.path == nil)
    }
}
