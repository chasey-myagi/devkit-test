import Foundation
import Network
import os

enum AgentHookEventType {
    case stop
    case notification
}

struct AgentHookEvent {
    let sessionID: String
    let type: AgentHookEventType
    let payload: [String: Any]
}

final class AgentNotifyServer: @unchecked Sendable {
    private var listener: NWListener?
    private let logger = Logger(subsystem: "com.chasey.DevKit", category: "AgentNotifyServer")
    let port: UInt16
    var onEvent: (@MainActor (AgentHookEvent) -> Void)?

    init(port: UInt16 = 19836) {
        self.port = port
    }

    func start() throws {
        let params = NWParameters.tcp
        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener?.start(queue: .global(qos: .utility))
        logger.info("AgentNotifyServer started on port \(self.port)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
        logger.info("AgentNotifyServer stopped")
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            defer { connection.cancel() }
            guard let self, let data else { return }
            let raw = String(data: data, encoding: .utf8) ?? ""
            guard let (path, body) = Self.parseHTTPRequest(raw) else {
                Self.sendResponse(connection: connection, status: 400)
                return
            }
            if let event = Self.parseEvent(from: body, path: path) {
                let onEvent = self.onEvent
                Task { @MainActor in
                    onEvent?(event)
                }
            }
            Self.sendResponse(connection: connection, status: 200)
        }
    }

    static func parseHTTPRequest(_ raw: String) -> (path: String, body: Data)? {
        let parts = raw.components(separatedBy: "\r\n\r\n")
        guard let headerSection = parts.first else { return nil }
        let firstLine = headerSection.components(separatedBy: "\r\n").first ?? ""
        let tokens = firstLine.split(separator: " ")
        guard tokens.count >= 2 else { return nil }
        let path = String(tokens[1])
        let body = parts.count > 1 ? Data(parts[1].utf8) : Data()
        return (path, body)
    }

    static func parseEvent(from body: Data, path: String) -> AgentHookEvent? {
        guard let sessionID = extractSessionID(from: path) else { return nil }
        let type: AgentHookEventType
        if path.hasSuffix("/stop") {
            type = .stop
        } else if path.hasSuffix("/notification") {
            type = .notification
        } else {
            return nil
        }
        let payload = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
        return AgentHookEvent(sessionID: sessionID, type: type, payload: payload)
    }

    static func extractSessionID(from path: String) -> String? {
        let components = path.split(separator: "/")
        guard components.count >= 3, components[0] == "agent" else { return nil }
        return String(components[1])
    }

    private static func sendResponse(connection: NWConnection, status: Int) {
        let response = "HTTP/1.1 \(status) OK\r\nContent-Length: 0\r\n\r\n"
        connection.send(content: response.data(using: .utf8), completion: .idempotent)
    }
}
