import Foundation
import SwiftTerm
import os

@MainActor
@Observable
final class AgentWorker: Identifiable {
    let id: String
    private(set) var currentSession: AgentSession?
    private(set) var terminalView: LocalProcessTerminalView?
    nonisolated private let logger = Logger(subsystem: "com.chasey.DevKit", category: "AgentWorker")

    var isIdle: Bool { currentSession == nil }

    init(id: String) {
        self.id = id
    }

    func start(session: AgentSession, workspacePath: String, prompt: String) {
        currentSession = session
        session.status = .running
        session.startedAt = .now

        let terminal = LocalProcessTerminalView(frame: .init(x: 0, y: 0, width: 800, height: 600))
        terminalView = terminal

        let env = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        terminal.startProcess(
            executable: "/bin/zsh",
            args: ["-l", "-c", "cd \(shellescape(workspacePath)) && claude --session-id \(session.id.uuidString) \(shellescape(prompt))"],
            environment: env,
            execName: "zsh"
        )

        logger.info("Worker \(self.id) started claude for issue #\(session.issueNumber)")
    }

    func enableInteraction() {
        currentSession?.status = .intervening
    }

    func release() {
        currentSession = nil
        terminalView = nil
    }

    private func shellescape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
