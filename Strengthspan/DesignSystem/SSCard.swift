import SwiftUI

/// Standard content card with a header row and arbitrary content.
struct SSCard<Content: View>: View {
    private let title: LocalizedStringKey
    private let systemImage: String
    private let content: Content

    init(_ title: LocalizedStringKey, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.m) {
            Label {
                Text(title)
                    .font(SSFont.headline)
                    .foregroundStyle(SSColor.textPrimary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(SSColor.accent)
            }
            .accessibilityAddTraits(.isHeader)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SSSpacing.l)
        .ssCardBackground()
    }
}

extension View {
    func ssCardBackground() -> some View {
        background(
            SSColor.surface,
            in: RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous)
                .strokeBorder(SSColor.separator, lineWidth: 1)
        )
    }
}
