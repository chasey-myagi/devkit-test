import Foundation
import SwiftData

enum WorkspaceError: Error, LocalizedError {
    case duplicateName(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .duplicateName(let name): return "Workspace '\(name)' already exists"
        case .notFound(let name): return "Workspace '\(name)' not found"
        }
    }
}

@MainActor
@Observable
final class WorkspaceManager {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func add(name: String, repoFullName: String, localPath: String) throws {
        let context = modelContainer.mainContext
        let existing = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.name == name }
        ))
        guard existing.isEmpty else {
            throw WorkspaceError.duplicateName(name)
        }
        let workspace = Workspace(name: name, repoFullName: repoFullName, localPath: localPath)
        context.insert(workspace)
        try context.save()
    }

    func delete(name: String) throws {
        let context = modelContainer.mainContext
        let workspaces = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.name == name }
        ))
        guard let workspace = workspaces.first else {
            throw WorkspaceError.notFound(name)
        }
        context.delete(workspace)
        try context.save()
    }

    func setActive(name: String) throws {
        let context = modelContainer.mainContext
        let all = try context.fetch(FetchDescriptor<Workspace>())
        for ws in all {
            ws.isActive = (ws.name == name)
        }
        try context.save()
    }

    func getActive() throws -> Workspace? {
        let context = modelContainer.mainContext
        let results = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.isActive == true }
        ))
        return results.first
    }

    func listAll() throws -> [Workspace] {
        let context = modelContainer.mainContext
        return try context.fetch(FetchDescriptor<Workspace>())
    }
}
