import SwiftUI

struct SSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SSButtonBody(configuration: configuration, prominent: true)
    }
}

struct SSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SSButtonBody(configuration: configuration, prominent: false)
    }
}

extension ButtonStyle where Self == SSPrimaryButtonStyle {
    static var ssPrimary: SSPrimaryButtonStyle { SSPrimaryButtonStyle() }
}

extension ButtonStyle where Self == SSSecondaryButtonStyle {
    static var ssSecondary: SSSecondaryButtonStyle { SSSecondaryButtonStyle() }
}

private struct SSButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let prominent: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(SSFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(prominent ? SSColor.onAccent : SSColor.accent)
            .padding(.horizontal, SSSpacing.l)
            .padding(.vertical, SSSpacing.m)
            .frame(maxWidth: .infinity, minHeight: SSLayout.minTouchTarget)
            .background(background, in: RoundedRectangle(cornerRadius: SSRadius.button, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var background: Color {
        prominent ? SSColor.accent : SSColor.accentSoft
    }
}
