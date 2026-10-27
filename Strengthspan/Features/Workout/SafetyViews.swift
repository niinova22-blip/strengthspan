import SwiftUI

/// "I don't feel well": asks what is happening, then hands the answer to the safety engine.
struct SafetyCheckView: View {
    let onSelect: (SafetyStopReason) -> Void
    let onCancel: () -> Void

    @State private var choosingRegions = false
    @State private var regions: Set<BodyRegion> = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    Text("safety.check.title")
                        .font(SSFont.largeTitle)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    if choosingRegions {
                        Text("safety.check.regions")
                            .font(SSFont.body)
                            .foregroundStyle(SSColor.textSecondary)
                        ForEach(BodyRegion.allCases, id: \.self) { region in
                            SSChoiceRow(region.titleKey, isSelected: regions.contains(region), allowsMultiple: true) {
                                if regions.contains(region) { regions.remove(region) } else { regions.insert(region) }
                            }
                        }
                    } else {
                        SSChoiceRow("safety.check.warningSigns", isSelected: false) { onSelect(.warningSigns) }
                            .accessibilityIdentifier("safety.check.warningSigns")
                        SSChoiceRow("safety.check.pain", isSelected: false) { choosingRegions = true }
                        SSChoiceRow("safety.check.unwell", isSelected: false) { onSelect(.generallyUnwell) }
                    }
                }
                .padding(SSSpacing.l)
            }
            VStack(spacing: SSSpacing.s) {
                if choosingRegions {
                    Button("safety.check.confirmPain") { onSelect(.pain(regions)) }
                        .buttonStyle(.ssPrimary)
                        .disabled(regions.isEmpty)
                }
                Button("common.cancel") {
                    if choosingRegions { choosingRegions = false } else { onCancel() }
                }
                .buttonStyle(.ssSecondary)
            }
            .padding(SSSpacing.l)
        }
    }
}

/// Shown when a session ends, normally or because of a safety stop.
struct SessionOutcomeView: View {
    enum Kind { case finished, stopped }

    let kind: Kind
    let decision: SafetyDecision
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    Image(systemName: kind == .finished ? "checkmark.circle" : "pause.circle")
                        .font(.system(size: 56))
                        .foregroundStyle(kind == .finished ? SSColor.accent : SSColor.caution)
                        .accessibilityHidden(true)
                    Text(kind == .finished ? LocalizedStringKey("outcome.finished.title") : "outcome.stopped.title")
                        .font(SSFont.largeTitle)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(kind == .finished ? LocalizedStringKey("outcome.finished.message") : "outcome.stopped.message")
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textSecondary)

                    if decision.showEmergencyAdvice {
                        notice("safety.emergency", systemImage: "phone.fill", color: SSColor.stop)
                    }
                    if decision.recommendProfessional {
                        notice("safety.professional", systemImage: "stethoscope", color: SSColor.caution)
                    }
                    if decision.newConstraints.contains(where: { $0.kind == .pain }) {
                        notice("safety.painAdjusted", systemImage: "slider.horizontal.3", color: SSColor.accent)
                    }
                }
                .padding(SSSpacing.l)
            }
            Button("common.done", action: onDone)
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("outcome.done")
                .padding(SSSpacing.l)
        }
    }

    private func notice(_ text: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        Label {
            Text(text)
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
        .padding(SSSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous)
                .strokeBorder(color, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}
