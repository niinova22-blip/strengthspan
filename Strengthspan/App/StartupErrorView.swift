import SwiftUI

struct StartupErrorView: View {
    var body: some View {
        VStack(spacing: SSSpacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(SSColor.caution)
                .accessibilityHidden(true)

            Text("startup.error.title")
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("startup.error.message")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(SSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SSColor.background.ignoresSafeArea())
    }
}

#if DEBUG
#Preview {
    StartupErrorView()
}
#endif
