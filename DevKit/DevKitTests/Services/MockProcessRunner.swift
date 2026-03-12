import Foundation
@testable import DevKit

final class MockProcessRunner: ProcessRunning, @unchecked Sendable {
    var stubbedResults: [String: Result<String, Error>] = [:]
    var recordedCommands: [(executable: String, arguments: [String])] = []

    func run(_ executable: String, arguments: [String]) async throws -> String {
        recordedCommands.append((executable, arguments))
        let key = ([executable] + arguments).joined(separator: " ")
        if let result = stubbedResults[key] {
            return try result.get()
        }
        if let result = stubbedResults[executable] {
            return try result.get()
        }
        throw ProcessRunnerError.notFound(executable)
    }

    func stubSuccess(for key: String, output: String) {
        stubbedResults[key] = .success(output)
    }

    func stubFailure(for key: String, error: Error) {
        stubbedResults[key] = .failure(error)
    }
}
