import Foundation

enum ProcessRunnerError: Error, LocalizedError {
    case notFound(String)
    case executionFailed(terminationStatus: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let cmd): return "Command not found: \(cmd)"
        case .executionFailed(let status, let stderr): return "Process exited with status \(status): \(stderr)"
        }
    }
}

protocol ProcessRunning: Sendable {
    func run(_ executable: String, arguments: [String]) async throws -> String
}

struct ProcessRunner: ProcessRunning {
    func run(_ executable: String, arguments: [String]) async throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let outStr = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw ProcessRunnerError.executionFailed(terminationStatus: process.terminationStatus, stderr: errStr)
        }
        return outStr
    }
}
