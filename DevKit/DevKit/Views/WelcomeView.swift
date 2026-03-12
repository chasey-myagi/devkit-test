import SwiftUI

struct WelcomeView: View {
    var onAddWorkspace: (String, String, String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showForm = false
    @State private var name = ""
    @State private var repo = ""
    @State private var localPath = ""
    @State private var addError: String?

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
                    // Inline workspace creation form
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
        VStack(spacing: DKSpacing.md) {
            VStack(alignment: .leading, spacing: DKSpacing.sm) {
                Text("ADD YOUR FIRST WORKSPACE")
                    .font(DKTypography.captionSmall())
                    .tracking(1.0)
                    .foregroundStyle(DKColor.Foreground.tertiary)

                formField("Workspace Name", text: $name, prompt: "my-project")
                formField("GitHub Repo", text: $repo, prompt: "owner/repo-name")

                HStack(spacing: DKSpacing.sm) {
                    formField("Local Path", text: $localPath, prompt: "/Users/you/projects/repo")
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            localPath = url.path
                        }
                    }
                    .buttonStyle(DKSecondaryButtonStyle())
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
                }
                .buttonStyle(DKGhostButtonStyle())

                Button {
                    guard !name.isEmpty, !repo.isEmpty, !localPath.isEmpty else {
                        addError = "All fields are required."
                        return
                    }
                    onAddWorkspace(name, repo, localPath)
                } label: {
                    Label("Create Workspace", systemImage: "checkmark")
                }
                .buttonStyle(DKPrimaryButtonStyle())
                .disabled(name.isEmpty || repo.isEmpty || localPath.isEmpty)
            }
        }
        .padding(DKSpacing.xl)
        .frame(maxWidth: 440)
        .background(DKColor.Surface.card.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
    }

    private func formField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: DKSpacing.xxs) {
            Text(label)
                .font(DKTypography.caption())
                .foregroundStyle(DKColor.Foreground.secondary)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(DKTypography.body())
                .padding(DKSpacing.sm)
                .background(DKColor.Surface.tertiary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
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
                Color(red: 0.18, green: 0.16, blue: 0.22),
                Color(red: 0.16, green: 0.15, blue: 0.18),
                Color(red: 0.22, green: 0.17, blue: 0.16),
                Color(red: 0.14, green: 0.14, blue: 0.18),
                DKColor.Surface.primary,
                Color(red: 0.18, green: 0.16, blue: 0.14),
                Color(red: 0.17, green: 0.14, blue: 0.23),
                Color(red: 0.15, green: 0.14, blue: 0.15),
                Color(red: 0.20, green: 0.18, blue: 0.14),
            ]
            : [
                Color(red: 0.93, green: 0.89, blue: 0.97),
                Color(red: 0.96, green: 0.94, blue: 0.95),
                Color(red: 0.99, green: 0.91, blue: 0.87),
                Color(red: 0.94, green: 0.92, blue: 0.97),
                DKColor.Surface.primary,
                Color(red: 0.98, green: 0.93, blue: 0.88),
                Color(red: 0.91, green: 0.82, blue: 0.99),
                Color(red: 0.96, green: 0.93, blue: 0.92),
                Color(red: 0.99, green: 0.96, blue: 0.85),
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
