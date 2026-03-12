import SwiftUI
import SwiftTerm

struct TerminalView: NSViewRepresentable {
    let terminalView: LocalProcessTerminalView

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        terminalView.configureNativeColors()
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        return terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}
}
