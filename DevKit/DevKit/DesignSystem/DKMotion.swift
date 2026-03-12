// DevKit/DevKit/DesignSystem/DKMotion.swift
import SwiftUI

enum DKMotion {
    enum Spring {
        static let `default` = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.65)
        static let stiff = Animation.spring(response: 0.25, dampingFraction: 0.9)
    }
    enum Ease {
        static let appear = Animation.easeOut(duration: 0.25)
        static let disappear = Animation.easeIn(duration: 0.15)
        static let hover = Animation.easeOut(duration: 0.2)
    }
}
