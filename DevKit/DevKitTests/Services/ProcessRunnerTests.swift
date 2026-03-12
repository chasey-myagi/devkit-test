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
}
