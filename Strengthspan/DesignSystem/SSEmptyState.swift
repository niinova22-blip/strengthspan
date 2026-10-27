import SwiftUI

/// Honest "nothing here yet" message. Shown instead of invented or placeholder values.
struct SSEmptyState: View {
    private let message: LocalizedStringKey
    private let systemImage: String

    init(_ message: LocalizedStringKey, systemImage: String = "circle.dashed") {
        self.message = message
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(message)
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(SSColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
