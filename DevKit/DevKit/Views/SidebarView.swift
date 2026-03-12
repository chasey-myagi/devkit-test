import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query private var workspaces: [Workspace]
    @Binding var selectedWorkspaceName: String?
    @Binding var selectedTab: SidebarTab

    /// Resolved workspace from name binding
    var selectedWorkspace: Workspace? {
        workspaces.first { $0.name == selectedWorkspaceName }
    }

    @State private var hoveredTab: SidebarTab?

    enum SidebarTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case issues = "Issues"
        case prs = "Pull Requests"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .issues: return "exclamationmark.circle"
            case .prs: return "arrow.triangle.pull"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Brand header
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DKColor.Accent.brand)
                Text("DevKit")
                    .font(.system(size: 18, design: .serif).weight(.medium))
                    .foregroundStyle(DKColor.Foreground.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DKSpacing.lg)
            .padding(.top, DKSpacing.lg)
            .padding(.bottom, DKSpacing.md)

            // Workspace selector
            Menu {
                Button {
                    selectedWorkspaceName = nil
                } label: {
                    Label("None", systemImage: "xmark.circle")
                }
                Divider()
                ForEach(workspaces) { ws in
                    Button {
                        selectedWorkspaceName = ws.name
                    } label: {
                        Label(ws.name, systemImage: "folder.fill")
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedWorkspaceName != nil ? "folder.fill" : "folder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DKColor.Accent.brand)
                    Text(selectedWorkspaceName ?? "Select Workspace")
                        .font(DKTypography.bodyMedium())
                        .foregroundStyle(DKColor.Foreground.primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DKColor.Foreground.tertiary)
                }
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, DKSpacing.sm)
                .background(DKColor.Surface.tertiary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
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
            VStack(spacing: DKSpacing.xxs) {
                ForEach(SidebarTab.allCases) { tab in
                    sidebarRow(tab: tab)
                }
            }
            .padding(.horizontal, DKSpacing.sm)

            Spacer()
        }
        .background(DKColor.Surface.secondary.opacity(0.5))
    }

    private func sidebarRow(tab: SidebarTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: DKSpacing.md) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? DKColor.Accent.brand : DKColor.Foreground.secondary)
                    .frame(width: 24)
                Text(tab.rawValue)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(selectedTab == tab ? DKColor.Foreground.primary : DKColor.Foreground.secondary)
                Spacer()
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DKRadius.md)
                    .fill(selectedTab == tab ? DKColor.Accent.brand.opacity(0.1) : (hoveredTab == tab ? DKColor.Surface.tertiary.opacity(0.5) : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            hoveredTab = isHovered ? tab : nil
        }
        .animation(DKMotion.Ease.hover, value: hoveredTab)
        .animation(DKMotion.Ease.hover, value: selectedTab)
    }
}
