import SwiftUI

/// Issue 创建/编辑表单（Sheet 弹出）
struct IssueFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: IssueFormViewModel
    let repoFullName: String
    let ghClient: GitHubCLIClient
    var onSaved: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(viewModel.isEditing ? "Edit Issue #\(viewModel.editingIssueNumber ?? 0)" : "New Issue")
                    .font(DKTypography.pageTitle())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(DKGhostButtonStyle())
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, DKSpacing.xl)
            .padding(.top, DKSpacing.xl)
            .padding(.bottom, DKSpacing.md)

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: DKSpacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        Text("Title")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        TextField("Issue title", text: $viewModel.title)
                            .textFieldStyle(.roundedBorder)
                            .font(DKTypography.body())
                    }

                    // Body
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        Text("Description")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        TextEditor(text: $viewModel.body)
                            .font(DKTypography.body())
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .padding(DKSpacing.sm)
                            .background(DKColor.Surface.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
                    }

                    // Labels
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        Text("Labels")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)

                        if viewModel.isLoadingOptions {
                            ProgressView()
                                .controlSize(.small)
                        } else if viewModel.availableLabels.isEmpty {
                            Text("No labels available")
                                .font(DKTypography.body())
                                .foregroundStyle(DKColor.Foreground.tertiary)
                        } else {
                            FlowLayout(spacing: DKSpacing.xs) {
                                ForEach(viewModel.availableLabels) { label in
                                    labelChip(label)
                                }
                            }
                        }
                    }

                    // Milestone
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        Text("Milestone")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        Picker("Milestone", selection: $viewModel.selectedMilestone) {
                            Text("None").tag(nil as String?)
                            ForEach(viewModel.availableMilestones) { ms in
                                Text(ms.title).tag(ms.title as String?)
                            }
                        }
                        .labelsHidden()
                    }

                    // Assignees（仅创建模式）
                    if !viewModel.isEditing {
                        VStack(alignment: .leading, spacing: DKSpacing.xs) {
                            Text("Assignees")
                                .font(DKTypography.caption())
                                .foregroundStyle(DKColor.Foreground.secondary)
                            TextField("Comma-separated usernames", text: $viewModel.assignees)
                                .textFieldStyle(.roundedBorder)
                                .font(DKTypography.body())
                        }
                    }

                    // Error
                    if let error = viewModel.error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(DKColor.Accent.critical)
                            .font(DKTypography.body())
                    }
                }
                .padding(DKSpacing.xl)
            }

            Divider()

            // 底部操作栏
            HStack {
                Spacer()
                Button {
                    Task {
                        await viewModel.save(repo: repoFullName, ghClient: ghClient)
                        if viewModel.saveSucceeded {
                            onSaved?()
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(viewModel.isEditing ? "Save Changes" : "Create Issue")
                    }
                }
                .buttonStyle(DKPrimaryButtonStyle())
                .disabled(!viewModel.isValid || viewModel.isSaving)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, DKSpacing.xl)
            .padding(.vertical, DKSpacing.md)
        }
        .frame(minWidth: 520, minHeight: 480)
        .background(DKColor.Surface.primary)
        .task {
            await viewModel.loadOptions(repo: repoFullName, ghClient: ghClient)
        }
    }

    /// 标签选择芯片
    @ViewBuilder
    private func labelChip(_ label: GHLabelInfo) -> some View {
        let isSelected = viewModel.selectedLabels.contains(label.name)
        Button {
            if isSelected {
                viewModel.selectedLabels.remove(label.name)
            } else {
                viewModel.selectedLabels.insert(label.name)
            }
        } label: {
            Text(label.name)
                .font(DKTypography.caption())
                .padding(.horizontal, DKSpacing.sm)
                .padding(.vertical, DKSpacing.xxs)
                .background(isSelected ? labelColor(label.color).opacity(0.25) : DKColor.Surface.tertiary)
                .foregroundStyle(isSelected ? labelColor(label.color) : DKColor.Foreground.secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? labelColor(label.color).opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// 将 GitHub 标签十六进制颜色转换为 SwiftUI Color
    private func labelColor(_ hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6,
              let rgb = UInt64(sanitized, radix: 16) else {
            return .secondary
        }
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}
