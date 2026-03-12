// DevKit/DevKitTests/DesignSystem/DKSpacingTests.swift
import Testing
@testable import DevKit

struct DKSpacingTests {
    @Test func spacingValuesFollowFourPointGrid() {
        #expect(DKSpacing.xxs == 2)
        #expect(DKSpacing.xs == 4)
        #expect(DKSpacing.sm == 8)
        #expect(DKSpacing.md == 12)
        #expect(DKSpacing.lg == 16)
        #expect(DKSpacing.xl == 24)
        #expect(DKSpacing.xxl == 32)
        #expect(DKSpacing.xxxl == 48)
    }

    @Test func radiusValuesAscend() {
        #expect(DKRadius.sm < DKRadius.md)
        #expect(DKRadius.md < DKRadius.lg)
        #expect(DKRadius.lg < DKRadius.xl)
        #expect(DKRadius.xl < DKRadius.hero)
    }

    @Test func radiusSpecificValues() {
        #expect(DKRadius.sm == 6)
        #expect(DKRadius.md == 12)
        #expect(DKRadius.lg == 20)
        #expect(DKRadius.xl == 28)
        #expect(DKRadius.hero == 32)
    }
}
