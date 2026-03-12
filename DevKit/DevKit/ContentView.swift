import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("DevKit")
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
