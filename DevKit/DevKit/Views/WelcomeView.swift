import SwiftUI

struct WelcomeView: View {
    var onOpenSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Full background mesh gradient
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

                // Setup steps
                VStack(spacing: DKSpacing.md) {
                    setupStep(title: "Add a Workspace", description: "Connect your GitHub repository", icon: "folder.badge.plus")
                    setupStep(title: "Authenticate GitHub", description: "Run gh auth login in Terminal", icon: "person.badge.key")
                    setupStep(title: "Start Tracking", description: "Issues and PRs sync automatically", icon: "arrow.triangle.2.circlepath")
                }
                .padding(.horizontal, DKSpacing.xxxl)
                .frame(maxWidth: 420)

                // CTA
                Button {
                    onOpenSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
                .buttonStyle(DKPrimaryButtonStyle())
                .padding(.top, DKSpacing.sm)

                Spacer()
                Spacer()
            }
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 20)
            .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.1), value: appeared)
        }
        .onAppear { appeared = true }
    }

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
