import SwiftUI

struct WelcomeView: View {
    var onAddWorkspace: (String, String, String) throws -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showForm = false
    @State private var name = ""
    @State private var repo = ""
    @State private var localPath = ""
    @State private var addError: String?
    @FocusState private var focusedField: FormField?

    private enum FormField: Hashable {
        case name, repo, path
    }

    private var formIsValid: Bool {
        !name.isEmpty && !repo.isEmpty && !localPath.isEmpty
    }

    var body: some View {
        ZStack {
            meshGradient
                .ignoresSafeArea()

            VStack(spacing: DKSpacing.xxl) {
                Spacer()

                // Brand icon
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(DKColor.Accent.brand.opacity(0.6))
                    .padding(.bottom, DKSpacing.sm)

                // Welcome text
                VStack(spacing: DKSpacing.sm) {
                    Text("Welcome to")
                        .font(DKTypography.body())
                        .foregroundStyle(DKColor.Foreground.tertiary)
                    Text("DevKit")
                        .font(.system(size: 42, design: .serif).weight(.regular))
                        .tracking(-0.5)
                        .foregroundStyle(DKColor.Foreground.primary)
                    Text("Your intelligent development companion.")
                        .font(DKTypography.body())
                        .foregroundStyle(DKColor.Foreground.secondary)
                        .padding(.top, DKSpacing.xs)
                }
                .multilineTextAlignment(.center)

                if showForm {
                    addWorkspaceForm
                        .transition(.opacity.combined(with: .offset(y: 12)))
                } else {
                    // Setup steps + CTA
                    VStack(spacing: DKSpacing.md) {
                        setupStep(title: "Add a Workspace", description: "Connect your GitHub repository", icon: "folder.badge.plus")
                        setupStep(title: "Authenticate GitHub", description: "Run gh auth login in Terminal", icon: "person.badge.key")
                        setupStep(title: "Start Tracking", description: "Issues and PRs sync automatically", icon: "arrow.triangle.2.circlepath")
                    }
                    .padding(.horizontal, DKSpacing.xxxl)
                    .frame(maxWidth: 420)
                    .transition(.opacity.combined(with: .offset(y: -12)))

                    Button {
                        withAnimation(DKMotion.Spring.default) {
                            showForm = true
                        }
                    } label: {
                        Label("Add Workspace", systemImage: "plus")
                    }
                    .buttonStyle(DKPrimaryButtonStyle())
                    .padding(.top, DKSpacing.sm)
                }

                Spacer()
                Spacer()
            }
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 20)
            .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.1), value: appeared)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Inline Add Workspace Form

    private var addWorkspaceForm: some View {
        VStack(spacing: DKSpacing.lg) {
            VStack(alignment: .leading, spacing: DKSpacing.lg) {
                Text("ADD YOUR FIRST WORKSPACE")
                    .font(DKTypography.captionSmall())
                    .tracking(1.0)
                    .foregroundStyle(DKColor.Foreground.tertiary)

                formField("Workspace Name", text: $name, prompt: "my-project", field: .name)
                    .onSubmit { focusedField = .repo }
                formField("GitHub Repo", text: $repo, prompt: "owner/repo-name", field: .repo)
                    .onSubmit { focusedField = .path }

                // Local path with Browse button
                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                    Text("Local Path")
                        .font(DKTypography.caption())
                        .foregroundStyle(DKColor.Foreground.secondary)
                    HStack(spacing: DKSpacing.sm) {
                        TextField("/Users/you/projects/repo", text: $localPath)
                            .textFieldStyle(.plain)
                            .font(DKTypography.body())
                            .focused($focusedField, equals: .path)
                            .padding(.horizontal, DKSpacing.md)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: DKRadius.sm)
                                    .fill(colorScheme == .dark ? DKColor.Surface.tertiary.opacity(0.5) : .white.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DKRadius.sm)
                                    .strokeBorder(
                                        focusedField == .path ? DKColor.Accent.brand : DKColor.Foreground.tertiary.opacity(0.2),
                                        lineWidth: focusedField == .path ? 1.5 : 0.5
                                    )
                            )
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            if panel.runModal() == .OK, let url = panel.url {
                                localPath = url.path
                            }
                        } label: {
                            Text("Browse")
                                .font(DKTypography.bodyMedium())
                                .foregroundStyle(DKColor.Foreground.primary)
                                .frame(height: 36)
                                .padding(.horizontal, DKSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: DKRadius.sm)
                                        .fill(colorScheme == .dark ? DKColor.Surface.tertiary : DKColor.Surface.secondary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DKRadius.sm)
                                        .strokeBorder(DKColor.Foreground.tertiary.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let addError {
                Text(addError)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.critical)
            }

            HStack(spacing: DKSpacing.md) {
                Button {
                    withAnimation(DKMotion.Spring.default) {
                        showForm = false
                        addError = nil
                    }
                } label: {
                    Text("Back")
                        .font(DKTypography.bodyMedium())
                        .foregroundStyle(DKColor.Foreground.secondary)
                        .frame(height: 36)
                        .padding(.horizontal, DKSpacing.xl)
                }
                .buttonStyle(.plain)

                Button {
                    guard formIsValid else {
                        addError = "All fields are required."
                        return
                    }
                    guard repo.contains("/") else {
                        addError = "Repo must be in owner/repo format."
                        return
                    }
                    guard FileManager.default.fileExists(atPath: localPath) else {
                        addError = "Path does not exist."
                        return
                    }
                    do {
                        try onAddWorkspace(name, repo, localPath)
                    } catch {
                        addError = error.localizedDescription
                    }
                } label: {
                    Label("Create Workspace", systemImage: "checkmark")
                }
                .buttonStyle(DKPrimaryButtonStyle())
                .disabled(!formIsValid)
            }
            .padding(.top, DKSpacing.xs)
        }
        .padding(DKSpacing.xl)
        .frame(maxWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: DKRadius.xl)
                .fill(colorScheme == .dark ? DKColor.Surface.card.opacity(0.9) : .white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DKRadius.xl)
                .strokeBorder(DKColor.Foreground.tertiary.opacity(0.08), lineWidth: 0.5)
        )
        .onAppear { focusedField = .name }
    }

    private func formField(_ label: String, text: Binding<String>, prompt: String, field: FormField) -> some View {
        VStack(alignment: .leading, spacing: DKSpacing.xs) {
            Text(label)
                .font(DKTypography.caption())
                .foregroundStyle(DKColor.Foreground.secondary)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(DKTypography.body())
                .focused($focusedField, equals: field)
                .padding(.horizontal, DKSpacing.md)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: DKRadius.sm)
                        .fill(colorScheme == .dark ? DKColor.Surface.tertiary.opacity(0.5) : .white.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DKRadius.sm)
                        .strokeBorder(
                            focusedField == field ? DKColor.Accent.brand : DKColor.Foreground.tertiary.opacity(0.2),
                            lineWidth: focusedField == field ? 1.5 : 0.5
                        )
                )
                .animation(DKMotion.Ease.hover, value: focusedField)
        }
    }

    // MARK: - Setup Steps

    private func setupStep(title: String, description: String, icon: String) -> some View {
        HStack(spacing: DKSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DKColor.Accent.brand)
                .frame(width: 44, height: 44)
                .background(DKColor.Accent.brand.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))

            VStack(alignment: .leading, spacing: DKSpacing.xxs) {
                Text(title)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Text(description)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }

            Spacer()
        }
        .padding(DKSpacing.md)
        .background(DKColor.Surface.card.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
    }

    // MARK: - Background

    @ViewBuilder
    private var meshGradient: some View {
        let colors: [Color] = colorScheme == .dark
            ? [
                Color(red: 0.12, green: 0.10, blue: 0.20),
                Color(red: 0.13, green: 0.12, blue: 0.17),
                Color(red: 0.15, green: 0.13, blue: 0.21),
                Color(red: 0.11, green: 0.11, blue: 0.18),
                DKColor.Surface.primary,
                Color(red: 0.14, green: 0.13, blue: 0.18),
                Color(red: 0.10, green: 0.09, blue: 0.19),
                Color(red: 0.13, green: 0.12, blue: 0.16),
                Color(red: 0.15, green: 0.14, blue: 0.20),
            ]
            : [
                Color(red: 0.93, green: 0.91, blue: 0.98),
                Color(red: 0.96, green: 0.95, blue: 0.97),
                Color(red: 0.97, green: 0.96, blue: 0.94),
                Color(red: 0.92, green: 0.91, blue: 0.98),
                DKColor.Surface.primary,
                Color(red: 0.96, green: 0.95, blue: 0.97),
                Color(red: 0.90, green: 0.88, blue: 0.98),
                Color(red: 0.96, green: 0.95, blue: 0.96),
                Color(red: 0.97, green: 0.96, blue: 0.95),
            ]
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: colors
        )
    }
}
