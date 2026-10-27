import SwiftUI

/// End-of-session report: effort, discomfort, dizziness and an optional note.
struct FeedbackView: View {
    let onSubmit: (SessionFeedbackInput, String?) -> Void

    @State private var rpe: Double = 5
    @State private var discomfort: Discomfort = .noDiscomfort
    @State private var regions: Set<BodyRegion> = []
    @State private var dizziness = false
    @State private var note = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.xl) {
                    Text("feedback.title")
                        .font(SSFont.largeTitle)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    section("feedback.rpe.title") {
                        Text("feedback.rpe.value \(Int(rpe)) \(rpeLabel)")
                            .font(SSFont.headline)
                            .foregroundStyle(SSColor.textPrimary)
                        Slider(value: $rpe, in: 1...10, step: 1) {
                            Text("feedback.rpe.title")
                        } minimumValueLabel: {
                            Text(verbatim: "1")
                        } maximumValueLabel: {
                            Text(verbatim: "10")
                        }
                        .tint(SSColor.accent)
                        .accessibilityValue(Text("feedback.rpe.value \(Int(rpe)) \(rpeLabel)"))
                    }

                    section("feedback.discomfort.title") {
                        ForEach(Discomfort.allCases, id: \.self) { option in
                            SSChoiceRow(LocalizedStringKey("feedback.discomfort." + option.rawValue), isSelected: discomfort == option) {
                                discomfort = option
                            }
                        }
                        if discomfort == .newOrSharp {
                            Text("feedback.regions.title")
                                .font(SSFont.callout)
                                .foregroundStyle(SSColor.textSecondary)
                                .padding(.top, SSSpacing.s)
                            ForEach(BodyRegion.allCases, id: \.self) { region in
                                SSChoiceRow(region.titleKey, isSelected: regions.contains(region), allowsMultiple: true) {
                                    if regions.contains(region) { regions.remove(region) } else { regions.insert(region) }
                                }
                            }
                        }
                    }

                    Toggle(isOn: $dizziness) {
                        Text("feedback.dizziness")
                            .font(SSFont.body)
                            .foregroundStyle(SSColor.textPrimary)
                    }
                    .tint(SSColor.accent)
                    .frame(minHeight: SSLayout.minTouchTarget)

                    section("feedback.note.title") {
                        TextField("feedback.note.placeholder", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(SSSpacing.m)
                            .ssCardBackground()
                    }
                }
                .padding(SSSpacing.l)
            }
            Button("feedback.save") { submit() }
                .buttonStyle(.ssPrimary)
                .disabled(discomfort == .newOrSharp && regions.isEmpty)
                .accessibilityIdentifier("feedback.save")
                .padding(SSSpacing.l)
                .background(SSColor.background)
        }
    }

    private var rpeLabel: String {
        switch Int(rpe) {
        case ...2: String(localized: "feedback.rpe.veryEasy")
        case 3...4: String(localized: "feedback.rpe.easy")
        case 5...6: String(localized: "feedback.rpe.moderate")
        case 7...8: String(localized: "feedback.rpe.hard")
        case 9: String(localized: "feedback.rpe.veryHard")
        default: String(localized: "feedback.rpe.max")
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Text(title)
                .font(SSFont.headline)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func submit() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSubmit(
            SessionFeedbackInput(
                rpe: Int(rpe),
                discomfort: discomfort,
                discomfortRegions: discomfort == .newOrSharp ? regions : [],
                dizzinessReported: dizziness
            ),
            trimmed.isEmpty ? nil : trimmed
        )
    }
}
