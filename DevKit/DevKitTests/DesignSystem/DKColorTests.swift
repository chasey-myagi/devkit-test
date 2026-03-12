import Testing
import SwiftUI
@testable import DevKit

struct DKColorTests {
    @Test func surfaceColorsExist() {
        let colors: [Color] = [
            DKColor.Surface.primary,
            DKColor.Surface.secondary,
            DKColor.Surface.tertiary,
            DKColor.Surface.card,
            DKColor.Surface.elevated,
        ]
        #expect(colors.count == 5)
    }

    @Test func foregroundColorsExist() {
        let colors: [Color] = [
            DKColor.Foreground.primary,
            DKColor.Foreground.secondary,
            DKColor.Foreground.tertiary,
            DKColor.Foreground.inverse,
        ]
        #expect(colors.count == 4)
    }

    @Test func accentColorsExist() {
        let colors: [Color] = [
            DKColor.Accent.critical,
            DKColor.Accent.warning,
            DKColor.Accent.caution,
            DKColor.Accent.positive,
            DKColor.Accent.info,
            DKColor.Accent.brand,
        ]
        #expect(colors.count == 6)
    }

    @Test func severityMappingCoversAllLevels() {
        let levels = ["s-1", "s0", "s1", "s2", "unknown"]
        for level in levels {
            let color: Color = DKColor.Accent.severity(level)
            #expect(type(of: color) == Color.self)
        }
    }
}
