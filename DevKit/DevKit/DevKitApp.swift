import SwiftUI
import SwiftData

@main
struct DevKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Workspace.self, CachedIssue.self])

        Settings {
            SettingsView()
        }
    }
}
