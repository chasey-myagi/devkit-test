import Foundation

struct ClaudeCLIStatus {
    let isInstalled: Bool
    let path: String?
}

struct ClaudeCLIDetector {
    let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    func detect() async -> ClaudeCLIStatus {
        do {
            let output = try await processRunner.run("which", arguments: ["claude"])
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return ClaudeCLIStatus(isInstalled: !path.isEmpty, path: path)
        } catch {
            return ClaudeCLIStatus(isInstalled: false, path: nil)
        }
    }
}
