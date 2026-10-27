import OSLog
import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appClock) private var clock
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model = OnboardingModel()
    @State private var saveFailed = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    stepContent
                }
                .padding(.horizontal, SSSpacing.l)
                .padding(.vertical, SSSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .background(SSColor.background.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: model.step)
        .alert("onboarding.saveFailed", isPresented: $saveFailed) {
            Button("common.ok", role: .cancel) {}
        }
    }

    // MARK: Chrome

    private var header: some View {
        HStack(spacing: SSSpacing.m) {
            if model.step != .welcome {
                Button {
                    model.back()
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.title3.weight(.semibold))
                        .frame(width: SSLayout.minTouchTarget, height: SSLayout.minTouchTarget)
                }
                .accessibilityLabel(Text("common.back"))
            }
            ProgressView(value: model.progress)
                .tint(SSColor.accent)
                .frame(maxWidth: .infinity, minHeight: SSLayout.minTouchTarget)
                .accessibilityLabel(Text("onboarding.progress"))
        }
        .padding(.horizontal, SSSpacing.l)
        .frame(minHeight: SSLayout.minTouchTarget)
    }

    private var footer: some View {
        Button(action: primaryAction) {
            Text(primaryTitle)
        }
        .buttonStyle(.ssPrimary)
        .disabled(!model.canContinue)
        .accessibilityIdentifier("onboarding.next")
        .padding(.horizontal, SSSpacing.l)
        .padding(.vertical, SSSpacing.m)
        .background(SSColor.background)
    }

    private var primaryTitle: LocalizedStringKey {
        switch model.step {
        case .welcome: "onboarding.start"
        case .result: "onboarding.finish"
        default: "common.continue"
        }
    }

    private func primaryAction() {
        guard model.step == .result else {
            model.next()
            return
        }
        guard let answers = model.answers else { return }
        do {
            try TrainingStore(context: modelContext, calendar: calendar).completeOnboarding(answers, now: clock.now)
        } catch {
            Logger.persistence.error("Saving onboarding failed: \(String(describing: error))")
            saveFailed = true
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            welcome
        case .ageRange:
            question("onboarding.ageRange.title")
            singleChoice(AgeRange.allCases, selection: model.ageRange) { model.ageRange = $0 }
        case .activity:
            question("onboarding.activity.title")
            singleChoice(ActivityLevel.allCases, selection: model.activity) { model.activity = $0 }
        case .experience:
            question("onboarding.experience.title")
            singleChoice(ExperienceLevel.allCases, selection: model.experience) { model.experience = $0 }
        case .goal:
            question("onboarding.goal.title")
            singleChoice(PrimaryGoal.allCases, selection: model.goal) { model.goal = $0 }
        case .days:
            question("onboarding.days.title", detail: "onboarding.days.detail")
            ForEach(calendar.orderedWeekdays, id: \.self) { weekday in
                SSChoiceRow(verbatim: calendar.weekdayName(weekday), isSelected: model.weekdays.contains(weekday), allowsMultiple: true) {
                    model.toggleWeekday(weekday)
                }
                .accessibilityIdentifier("option.weekday.\(weekday)")
            }
        case .sessionLength:
            question("onboarding.sessionLength.title")
            ForEach(SessionLength.allCases, id: \.self) { length in
                SSChoiceRow(length.titleKey, isSelected: model.sessionLength == length) { model.sessionLength = length }
                    .accessibilityIdentifier("option.sessionLength.\(length.rawValue)")
            }
        case .equipment:
            question("onboarding.equipment.title", detail: "onboarding.equipment.detail")
            SSChoiceRow(Equipment.bodyweightOnly.titleKey, isSelected: model.hasChosenEquipment && model.equipment.isEmpty, allowsMultiple: true) {
                model.chooseBodyweightOnly()
            }
            .accessibilityIdentifier(Equipment.bodyweightOnly.localizationKey)
            ForEach([Equipment.dumbbells, .resistanceBand], id: \.self) { item in
                SSChoiceRow(item.titleKey, isSelected: model.equipment.contains(item), allowsMultiple: true) {
                    model.toggleEquipment(item)
                }
                .accessibilityIdentifier(item.localizationKey)
            }
        case .screening:
            question("onboarding.screening.title", detail: "onboarding.screening.detail")
            ForEach(ScreeningQuestion.allCases, id: \.self) { item in
                screeningRow(item)
            }
        case .painRegions:
            question("onboarding.painRegions.title", detail: "onboarding.painRegions.detail")
            ForEach(BodyRegion.allCases, id: \.self) { region in
                SSChoiceRow(region.titleKey, isSelected: model.painRegions.contains(region), allowsMultiple: true) {
                    model.togglePainRegion(region)
                }
                .accessibilityIdentifier(region.localizationKey)
            }
        case .result:
            result
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: SSSpacing.l) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 56))
                .foregroundStyle(SSColor.accent)
                .accessibilityHidden(true)
            Text("onboarding.welcome.title")
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("onboarding.welcome.message")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
            Text("onboarding.welcome.privacy")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        }
    }

    @ViewBuilder
    private var result: some View {
        let outcome = model.screeningResult.outcome
        VStack(alignment: .leading, spacing: SSSpacing.l) {
            Image(systemName: outcome == .cleared ? "checkmark.seal" : "stethoscope")
                .font(.system(size: 48))
                .foregroundStyle(outcome == .cleared ? SSColor.accent : SSColor.caution)
                .accessibilityHidden(true)
            Text(outcome == .cleared ? LocalizedStringKey("onboarding.result.cleared.title") : "onboarding.result.review.title")
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(outcome == .cleared ? LocalizedStringKey("onboarding.result.cleared.message") : "onboarding.result.review.message")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
            Text("settings.disclaimer")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        }
    }

    // MARK: Building blocks

    private func question(_ title: LocalizedStringKey, detail: LocalizedStringKey? = nil) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Text(title)
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail)
                    .font(SSFont.callout)
                    .foregroundStyle(SSColor.textSecondary)
            }
        }
        .padding(.bottom, SSSpacing.s)
    }

    private func singleChoice<Option: LocalizedOption>(
        _ options: [Option],
        selection: Option?,
        select: @escaping (Option) -> Void
    ) -> some View {
        ForEach(options, id: \.self) { option in
            SSChoiceRow(option.titleKey, isSelected: selection == option) { select(option) }
                .accessibilityIdentifier(option.localizationKey)
        }
    }

    private func screeningRow(_ item: ScreeningQuestion) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Text(item.titleKey)
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: SSSpacing.s) {
                answerButton(item, answer: true)
                answerButton(item, answer: false)
            }
        }
        .padding(SSSpacing.l)
        .ssCardBackground()
    }

    private func answerButton(_ item: ScreeningQuestion, answer: Bool) -> some View {
        let isSelected = model.screeningAnswers[item] == answer
        return Button {
            model.screeningAnswers[item] = answer
        } label: {
            Text(answer ? LocalizedStringKey("common.yes") : "common.no")
                .font(SSFont.headline)
                .frame(maxWidth: .infinity, minHeight: SSLayout.minTouchTarget)
                .foregroundStyle(isSelected ? SSColor.onAccent : SSColor.textPrimary)
                .background(isSelected ? SSColor.accent : SSColor.accentSoft, in: RoundedRectangle(cornerRadius: SSRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("\(item.textKey).\(answer ? "yes" : "no")")
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .modelContainer(PreviewSupport.container(populated: false))
}
#endif
