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

    /// 判断是否为 GitHub API rate limit 错误（HTTP 403 + stderr 包含相关关键词）
    var isRateLimited: Bool {
        guard case .executionFailed(_, let stderr) = self else { return false }
        let lowered = stderr.lowercased()
        return lowered.contains("rate limit") || lowered.contains("api rate limit")
            || lowered.contains("403")
    }
}

protocol ProcessRunning: Sendable {
    func run(_ executable: String, arguments: [String]) async throws -> String
}

struct ProcessRunner: ProcessRunning {
    func run(_ executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [executable] + arguments
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // 并行读取 stdout/stderr 防止管道缓冲区满导致 deadlock
                final class DataBox: @unchecked Sendable {
                    var value = Data()
                }
                let outBox = DataBox()
                let errBox = DataBox()
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.global().async {
                    outBox.value = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }
                group.enter()
                DispatchQueue.global().async {
                    errBox.value = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }
                group.wait()
                process.waitUntilExit()

                let outStr = String(data: outBox.value, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errStr = String(data: errBox.value, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus != 0 {
                    continuation.resume(throwing: ProcessRunnerError.executionFailed(
                        terminationStatus: process.terminationStatus, stderr: errStr
                    ))
                } else {
                    continuation.resume(returning: outStr)
                }
            }
        }
    }
}
