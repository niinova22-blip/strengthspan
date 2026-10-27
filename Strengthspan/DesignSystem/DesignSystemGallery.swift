#if DEBUG
import SwiftUI

/// Visual reference for design review in Xcode Previews. Not reachable in the app.
/// Strings here are intentionally not localized.
struct DesignSystemGallery: View {
    private let swatches: [(name: String, color: Color)] = [
        ("background", SSColor.background),
        ("surface", SSColor.surface),
        ("textPrimary", SSColor.textPrimary),
        ("textSecondary", SSColor.textSecondary),
        ("accent", SSColor.accent),
        ("accentSoft", SSColor.accentSoft),
        ("separator", SSColor.separator),
        ("caution", SSColor.caution),
        ("stop", SSColor.stop),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SSSpacing.xl) {
                Text(verbatim: "Large title").font(SSFont.largeTitle)
                Text(verbatim: "Title").font(SSFont.title)
                Text(verbatim: "Headline").font(SSFont.headline)
                Text(verbatim: "Body text for longer explanations.").font(SSFont.body)
                Text(verbatim: "15").font(SSFont.metric)

                ForEach(swatches, id: \.name) { swatch in
                    HStack(spacing: SSSpacing.m) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(swatch.color)
                            .frame(width: 44, height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(SSColor.separator))
                        Text(verbatim: swatch.name).font(SSFont.callout)
                    }
                }

                Button {} label: { Text(verbatim: "Primary action") }
                    .buttonStyle(.ssPrimary)
                Button {} label: { Text(verbatim: "Secondary action") }
                    .buttonStyle(.ssSecondary)
                Button {} label: { Text(verbatim: "Disabled") }
                    .buttonStyle(.ssPrimary)
                    .disabled(true)
            }
            .foregroundStyle(SSColor.textPrimary)
            .padding(SSSpacing.l)
        }
        .background(SSColor.background.ignoresSafeArea())
    }
}

#Preview("Light") {
    DesignSystemGallery()
}

#Preview("Dark, AX size") {
    DesignSystemGallery()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
#endif
