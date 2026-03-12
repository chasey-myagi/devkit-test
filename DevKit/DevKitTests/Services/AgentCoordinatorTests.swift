import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("AgentCoordinator Tests")
struct AgentCoordinatorTests {
    @Test @MainActor func initialStateHasNoWorkers() {
        let coordinator = AgentCoordinator()
        #expect(coordinator.workers.isEmpty)
    }

    @Test @MainActor func setupCreatesWorkers() async {
        let coordinator = AgentCoordinator()
        let container = try! ModelContainer(
            for: Workspace.self, CachedIssue.self, CachedPR.self, AgentSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        coordinator.setup(modelContainer: container, maxConcurrency: 3)
        #expect(coordinator.workers.count == 3)
    }
}
