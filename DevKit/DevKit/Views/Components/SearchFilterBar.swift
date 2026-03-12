import SwiftUI

/// 搜索栏 + 过滤器菜单组件
struct SearchFilterBar: View {
    @Bindable var viewModel: SearchFilterViewModel
    var availableLabels: [String] = []
    var availableAssignees: [String] = []
    var availableMilestones: [String] = []

    var body: some View {
        HStack(spacing: DKSpacing.md) {
            // 搜索框
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DKColor.Foreground.tertiary)
                TextField("Search...", text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.updateSearch($0) }
                ))
                .textFieldStyle(.plain)
                .font(DKTypography.body())
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.updateSearch("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DKColor.Foreground.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)
            .background(DKColor.Surface.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
            .frame(maxWidth: 280)

            // Label 过滤菜单
            if !availableLabels.isEmpty {
                filterMenuForLabels()
            }

            // Assignee 过滤菜单
            if !availableAssignees.isEmpty {
                filterMenuForAssignee()
            }

            // Milestone 过滤菜单
            if !availableMilestones.isEmpty {
                filterMenuForMilestone()
            }

            // 清除按钮
            if viewModel.hasActiveFilters {
                Button("Clear") {
                    viewModel.clearAll()
                }
                .buttonStyle(DKGhostButtonStyle())
            }

            Spacer()
        }
        .padding(.horizontal, DKSpacing.lg)
        .padding(.vertical, DKSpacing.sm)
    }

    // MARK: - 过滤菜单

    private func filterMenuForLabels() -> some View {
        Menu {
            ForEach(availableLabels, id: \.self) { label in
                Button {
                    if viewModel.selectedLabels.contains(label) {
                        viewModel.selectedLabels.remove(label)
                    } else {
                        viewModel.selectedLabels.insert(label)
                    }
                } label: {
                    HStack {
                        Text(label)
                        if viewModel.selectedLabels.contains(label) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DKSpacing.xs) {
                Image(systemName: "tag")
                    .font(.system(size: 11))
                Text("Label")
                    .font(DKTypography.caption())
                if !viewModel.selectedLabels.isEmpty {
                    Text("\(viewModel.selectedLabels.count)")
                        .font(DKTypography.captionSmall())
                        .padding(.horizontal, DKSpacing.xs)
                        .background(DKColor.Accent.brand.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(viewModel.selectedLabels.isEmpty ? DKColor.Foreground.secondary : DKColor.Accent.brand)
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xs)
            .background(DKColor.Surface.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
        }
        .buttonStyle(.plain)
    }

    private func filterMenuForAssignee() -> some View {
        Menu {
            Button {
                viewModel.selectedAssignee = nil
            } label: {
                HStack {
                    Text("All")
                    if viewModel.selectedAssignee == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
            ForEach(availableAssignees, id: \.self) { assignee in
                Button {
                    viewModel.selectedAssignee = assignee
                } label: {
                    HStack {
                        Text(assignee)
                        if viewModel.selectedAssignee == assignee {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DKSpacing.xs) {
                Image(systemName: "person")
                    .font(.system(size: 11))
                Text(viewModel.selectedAssignee ?? "Assignee")
                    .font(DKTypography.caption())
            }
            .foregroundStyle(viewModel.selectedAssignee != nil ? DKColor.Accent.brand : DKColor.Foreground.secondary)
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xs)
            .background(DKColor.Surface.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
        }
        .buttonStyle(.plain)
    }

    private func filterMenuForMilestone() -> some View {
        Menu {
            Button {
                viewModel.selectedMilestone = nil
            } label: {
                HStack {
                    Text("All")
                    if viewModel.selectedMilestone == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
            ForEach(availableMilestones, id: \.self) { milestone in
                Button {
                    viewModel.selectedMilestone = milestone
                } label: {
                    HStack {
                        Text(milestone)
                        if viewModel.selectedMilestone == milestone {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DKSpacing.xs) {
                Image(systemName: "flag")
                    .font(.system(size: 11))
                Text(viewModel.selectedMilestone ?? "Milestone")
                    .font(DKTypography.caption())
            }
            .foregroundStyle(viewModel.selectedMilestone != nil ? DKColor.Accent.brand : DKColor.Foreground.secondary)
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xs)
            .background(DKColor.Surface.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
        }
        .buttonStyle(.plain)
    }
}
