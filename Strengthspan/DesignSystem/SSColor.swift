import SwiftUI
import UIKit

/// Semantic color tokens. Each token adapts to light/dark mode and to Increase Contrast.
/// Values and contrast targets are documented in docs/03-ux-akislari-ve-tasarim-sistemi.md.
enum SSColor {
    static let background = dynamic(light: 0xF6F7F6, dark: 0x0D1114)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x182025)
    static let textPrimary = dynamic(light: 0x14202B, dark: 0xF1F4F6, lightHighContrast: 0x000000, darkHighContrast: 0xFFFFFF)
    static let textSecondary = dynamic(light: 0x4A5560, dark: 0xA7B1BA, lightHighContrast: 0x2E3740, darkHighContrast: 0xD0D7DD)
    static let accent = dynamic(light: 0x0F766E, dark: 0x2DD4BF, lightHighContrast: 0x0B5A54, darkHighContrast: 0x5EEAD4)
    static let accentSoft = dynamic(light: 0xE3F2F0, dark: 0x11302D)
    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x0D1114)
    static let separator = dynamic(light: 0xE1E6E9, dark: 0x29323A, lightHighContrast: 0x9AA5AE, darkHighContrast: 0x5B6670)
    /// Gentle attention, e.g. "this measurement wasn't reliable". Never used for poor results.
    static let caution = dynamic(light: 0x8A5300, dark: 0xF5B451)
    /// Reserved for the safety stop screen.
    static let stop = dynamic(light: 0xB42318, dark: 0xF97066)

    private static func dynamic(
        light: UInt32,
        dark: UInt32,
        lightHighContrast: UInt32? = nil,
        darkHighContrast: UInt32? = nil
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let highContrast = traits.accessibilityContrast == .high
            let hex = switch traits.userInterfaceStyle {
            case .dark: highContrast ? (darkHighContrast ?? dark) : dark
            default: highContrast ? (lightHighContrast ?? light) : light
            }
            return UIColor(hex: hex)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
