import SwiftUI
import SwiftData

@main
struct DevKitApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshIssues, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
        .modelContainer(modelContainer)
    }
}

extension Notification.Name {
    static let refreshIssues = Notification.Name("DevKit.refreshIssues")
}
