// DevKit/DevKit/DesignSystem/DKShadow.swift
import SwiftUI

enum DKShadow {
    struct Value: Sendable {
        let opacity: Double
        let radius: CGFloat
        let y: CGFloat
    }

    static let none = Value(opacity: 0, radius: 0, y: 0)
    static let sm = Value(opacity: 0.05, radius: 2, y: 1)
    static let md = Value(opacity: 0.08, radius: 8, y: 2)
    static let lg = Value(opacity: 0.12, radius: 16, y: 4)
}

extension View {
    func dkShadow(_ shadow: DKShadow.Value) -> some View {
        let warmBlack = Color(red: 0.1, green: 0.1, blue: 0.1)
        return self.shadow(color: warmBlack.opacity(shadow.opacity), radius: shadow.radius, y: shadow.y)
    }
}
