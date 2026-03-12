import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("WorkspaceManager")
struct WorkspaceManagerTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, configurations: config)
    }

    @Test @MainActor func addsWorkspace() throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try manager.add(name: "moi", repoFullName: "matrixorigin/matrixflow", localPath: "/tmp/test")
        let workspaces = try manager.listAll()
        #expect(workspaces.count == 1)
        #expect(workspaces[0].name == "moi")
        #expect(workspaces[0].repoFullName == "matrixorigin/matrixflow")
    }

    @Test @MainActor func rejectsDuplicateName() throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try manager.add(name: "moi", repoFullName: "owner/repo", localPath: "/tmp/a")
        #expect(throws: WorkspaceError.self) {
            try manager.add(name: "moi", repoFullName: "owner/repo2", localPath: "/tmp/b")
        }
    }

    @Test @MainActor func deletesWorkspace() throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try manager.add(name: "test", repoFullName: "o/r", localPath: "/tmp")
        try manager.delete(name: "test")
        let workspaces = try manager.listAll()
        #expect(workspaces.isEmpty)
    }

    @Test @MainActor func setsActiveWorkspace() throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try manager.add(name: "a", repoFullName: "o/r1", localPath: "/tmp/a")
        try manager.add(name: "b", repoFullName: "o/r2", localPath: "/tmp/b")
        try manager.setActive(name: "b")
        let active = try manager.getActive()
        #expect(active?.name == "b")
    }
}
