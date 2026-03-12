// DevKit/DevKitTests/DesignSystem/DKTypographyTests.swift
import Testing
import SwiftUI
@testable import DevKit

struct DKTypographyTests {
    @Test func allFontFunctionsReturnNonNil() {
        let fonts: [Font] = [
            DKTypography.heroTitle(),
            DKTypography.pageTitle(),
            DKTypography.sectionHeader(),
            DKTypography.cardTitle(),
            DKTypography.body(),
            DKTypography.bodyMedium(),
            DKTypography.caption(),
            DKTypography.captionSmall(),
            DKTypography.issueNumber(),
        ]
        #expect(fonts.count == 9)
    }

    @Test func textStyleTokenCoverage() {
        let tokens: [DKTextStyleToken] = [
            .heroTitle, .pageTitle, .sectionHeader, .cardTitle,
            .body, .bodyMedium, .caption, .captionSmall, .issueNumber,
        ]
        for token in tokens {
            let modifier = token.modifier
            #expect(modifier.tracking.isFinite)
            #expect(modifier.lineSpacing >= 0)
        }
    }
}
