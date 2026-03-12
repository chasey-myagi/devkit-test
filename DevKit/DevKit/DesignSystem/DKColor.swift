import SwiftUI

enum DKColor {
    enum Surface {
        static let primary = Color("SurfacePrimary")
        static let secondary = Color("SurfaceSecondary")
        static let tertiary = Color("SurfaceTertiary")
        static let card = Color("SurfaceCard")
        static let elevated = Color("SurfaceElevated")
    }

    /// Named Foreground (not Text) to avoid collision with SwiftUI.Text
    enum Foreground {
        static let primary = Color("TextPrimary")
        static let secondary = Color("TextSecondary")
        static let tertiary = Color("TextTertiary")
        static let inverse = Color("TextInverse")
    }

    enum Accent {
        static let critical = Color("AccentCritical")
        static let warning = Color("AccentWarning")
        static let caution = Color("AccentCaution")
        static let positive = Color("AccentPositive")
        static let info = Color("AccentInfo")
        static let brand = Color("AccentBrand")

        static func severity(_ level: String) -> Color {
            switch level {
            case "s-1": critical
            case "s0": warning
            case "s1": caution
            case "s2": positive
            default: Color.secondary
            }
        }

        /// Tint background with different opacity for light/dark mode
        static func tintBackground(_ color: Color, colorScheme: ColorScheme) -> Color {
            color.opacity(colorScheme == .dark ? 0.12 : 0.20)
        }
    }
}
