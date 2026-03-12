import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query private var workspaces: [Workspace]
    @Binding var selectedWorkspaceName: String?
    @Binding var selectedTab: SidebarTab
    @State private var showSettings = false

    /// Resolved workspace from name binding
    var selectedWorkspace: Workspace? {
        workspaces.first { $0.name == selectedWorkspaceName }
    }

    @State private var hoveredTab: SidebarTab?

    enum SidebarTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case issues = "Issues"
        case prs = "PRs"
        case actions = "Actions"
        case agents = "Agents"
        case reports = "Reports"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .issues: return "exclamationmark.circle"
            case .prs: return "arrow.triangle.pull"
            case .actions: return "gearshape.2"
            case .agents: return "terminal"
            case .reports: return "chart.bar.doc.horizontal"
            }
        }
        var shortcutKey: KeyEquivalent {
            switch self {
            case .overview: return "1"
            case .issues: return "2"
            case .prs: return "3"
            case .actions: return "4"
            case .agents: return "5"
            case .reports: return "6"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Brand header — icon + name + subtitle
            VStack(alignment: .leading, spacing: DKSpacing.xs) {
                HStack(spacing: DKSpacing.sm) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DKColor.Accent.brand)
                    Text("DevKit")
                        .font(.system(size: 20, design: .serif).weight(.semibold))
                        .foregroundStyle(DKColor.Foreground.primary)
                }
                Text("GitHub Project Manager")
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DKSpacing.lg)
            .padding(.top, DKSpacing.xl)
            .padding(.bottom, DKSpacing.lg)

            // Workspace selector
            Menu {
                ForEach(workspaces) { ws in
                    Button {
                        selectedWorkspaceName = ws.name
                    } label: {
                        HStack {
                            Label(ws.name, systemImage: "folder.fill")
                            if ws.name == selectedWorkspaceName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                if !workspaces.isEmpty {
                    Divider()
                }
                Button {
                    selectedWorkspaceName = nil
                } label: {
                    Label("Clear Selection", systemImage: "xmark.circle")
                }
            } label: {
                HStack(spacing: DKSpacing.sm) {
                    Image(systemName: selectedWorkspaceName != nil ? "folder.fill" : "folder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DKColor.Accent.brand)
                    Text(selectedWorkspaceName ?? "Workspace")
                        .font(DKTypography.bodyMedium())
                        .foregroundStyle(DKColor.Foreground.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DKColor.Foreground.tertiary)
                }
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, 10)
                .background(DKColor.Surface.tertiary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DKSpacing.md)
            .padding(.bottom, DKSpacing.xl)

            // Section label
            Text("NAVIGATION")
                .font(DKTypography.captionSmall())
                .tracking(1.0)
                .foregroundStyle(DKColor.Foreground.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DKSpacing.lg)
                .padding(.bottom, DKSpacing.sm)

            // Navigation tabs
            VStack(spacing: DKSpacing.xs) {
                ForEach(SidebarTab.allCases) { tab in
                    sidebarRow(tab: tab)
                }
            }
            .padding(.horizontal, DKSpacing.sm)

            Spacer()

            // Bottom settings button
            Divider()
                .padding(.horizontal, DKSpacing.md)

            Button {
                showSettings = true
            } label: {
                HStack(spacing: DKSpacing.md) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DKColor.Foreground.secondary)
                        .frame(width: 24)
                    Text("Settings")
                        .font(DKTypography.bodyMedium())
                        .foregroundStyle(DKColor.Foreground.secondary)
                    Spacer()
                }
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, DKSpacing.sm)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.md)
        }
        .background(DKColor.Surface.secondary.opacity(0.5))
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 600, minHeight: 400)
        }
    }

    private func sidebarRow(tab: SidebarTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: DKSpacing.md) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? DKColor.Accent.brand : DKColor.Foreground.secondary)
                    .frame(width: 24)
                Text(tab.rawValue)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(selectedTab == tab ? DKColor.Foreground.primary : DKColor.Foreground.secondary)
                Spacer()
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DKRadius.sm)
                    .fill(selectedTab == tab ? DKColor.Accent.brand.opacity(0.12) : (hoveredTab == tab ? DKColor.Surface.tertiary.opacity(0.5) : .clear))
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(tab.shortcutKey, modifiers: .command)
        .onHover { isHovered in
            hoveredTab = isHovered ? tab : nil
        }
        .animation(DKMotion.Ease.hover, value: hoveredTab)
        .animation(DKMotion.Ease.hover, value: selectedTab)
    }
}
