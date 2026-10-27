import Foundation
import SwiftData

/// Answers collected during onboarding.
struct OnboardingAnswers: Equatable, Sendable {
    var ageRange: AgeRange
    var activityLevel: ActivityLevel
    var experienceLevel: ExperienceLevel
    var primaryGoal: PrimaryGoal
    var weekdays: Set<Int>
    var sessionLength: SessionLength
    var equipment: Set<Equipment>
    var screeningYes: Set<ScreeningQuestion>
    var painRegions: Set<BodyRegion>
}

enum PlanState {
    case blocked(PlanBlockReason)
    case ready(WorkoutPlan)
}

/// Bridges the pure planning/safety rules and the SwiftData store.
@MainActor
struct TrainingStore {
    let context: ModelContext
    var calendar: Calendar = .current
    var generator = PlanGenerator()

    // MARK: Profile

    func profile() throws -> UserProfile? {
        try context.fetch(FetchDescriptor<UserProfile>()).first
    }

    @discardableResult
    func completeOnboarding(_ answers: OnboardingAnswers, now: Date) throws -> UserProfile {
        let screening = ScreeningEvaluator.evaluate(yesAnswers: answers.screeningYes, painRegions: answers.painRegions)
        let profile = UserProfile(
            createdAt: now,
            ageRange: answers.ageRange,
            activityLevel: answers.activityLevel,
            experienceLevel: answers.experienceLevel,
            primaryGoal: answers.primaryGoal,
            screeningOutcome: screening.outcome
        )
        profile.safetyScreeningCompletedAt = now
        profile.onboardingCompletedAt = now
        context.insert(profile)
        profile.preferences = UserPreferences(
            updatedAt: now,
            weeklySessionTarget: answers.weekdays.count,
            sessionLength: answers.sessionLength,
            equipment: answers.equipment,
            preferredWeekdays: Array(answers.weekdays)
        )
        for spec in screening.constraints {
            profile.safetyConstraints.append(SafetyConstraint(kind: spec.kind, bodyRegion: spec.region, source: .onboarding, reportedAt: now))
        }
        try context.save()
        return profile
    }

    /// The user confirms a health professional has cleared them to exercise.
    func confirmProfessionalClearance(now: Date) throws {
        guard let profile = try profile() else { return }
        profile.screeningOutcome = .cleared
        profile.professionalClearanceConfirmedAt = now
        profile.updatedAt = now
        try context.save()
    }

    /// The user reports that the dizziness that paused training has passed.
    func resolveDizziness(now: Date) throws {
        for constraint in try activeConstraints() where constraint.kind == .dizziness {
            constraint.resolvedAt = now
        }
        try context.save()
    }

    func activeConstraints() throws -> [SafetyConstraint] {
        try context.fetch(FetchDescriptor<SafetyConstraint>()).filter(\.isActive)
    }

    func trainingProfile(for profile: UserProfile) throws -> TrainingProfile {
        let preferences = profile.preferences
        return TrainingProfile(
            sessionLength: preferences?.sessionLength ?? .short,
            equipment: preferences?.equipment ?? [],
            preferredWeekdays: Set(preferences?.preferredWeekdays ?? []),
            goal: profile.primaryGoal,
            screening: profile.screeningOutcome,
            constraints: try activeConstraints().map { ConstraintSpec(kind: $0.kind, region: $0.bodyRegion) }
        )
    }

    // MARK: Plan

    /// Returns the plan covering `now`, generating a new seven-day plan when none is active.
    func ensureCurrentPlan(now: Date) throws -> PlanState {
        guard let profile = try profile() else { return .blocked(.notScreened) }
        let training = try trainingProfile(for: profile)
        if case .blocked(let reason) = SafetyEngine.planPermission(screening: training.screening, constraints: training.constraints) {
            return .blocked(reason)
        }
        if let current = try activePlans().first(where: { covers($0, now) }) {
            return .ready(current)
        }
        return try generatePlan(for: training, now: now)
    }

    /// Replaces the remaining part of the current plan, e.g. after a new safety constraint.
    func regeneratePlan(now: Date) throws -> PlanState {
        guard let profile = try profile() else { return .blocked(.notScreened) }
        return try generatePlan(for: try trainingProfile(for: profile), now: now)
    }

    private func generatePlan(for training: TrainingProfile, now: Date) throws -> PlanState {
        retireActivePlans(now: now)

        let today = calendar.startOfDay(for: now)
        let trainedToday = try completedSessions().contains { calendar.isDate($0.completedAt ?? .distantPast, inSameDayAs: now) }
        let start = trainedToday ? (calendar.date(byAdding: .day, value: 1, to: today) ?? today) : today

        let outcome = generator.generate(
            profile: training,
            progress: try progressByExercise(for: training),
            start: start,
            daysSinceLastWorkout: try daysSinceLastWorkout(now: now),
            calendar: calendar
        )
        switch outcome {
        case .blocked(let reason):
            try context.save()
            return .blocked(reason)
        case .plan(let week):
            let plan = persist(week, now: now)
            try context.save()
            return .ready(plan)
        }
    }

    private func activePlans() throws -> [WorkoutPlan] {
        try context.fetch(FetchDescriptor<WorkoutPlan>()).filter { $0.status == .active }
    }

    /// A plan that starts tomorrow (created after today's workout) also counts as current.
    private func covers(_ plan: WorkoutPlan, _ date: Date) -> Bool {
        guard let end = calendar.date(byAdding: .day, value: PlanGenerator.periodDays, to: plan.weekStartDate),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else { return false }
        return plan.weekStartDate <= tomorrow && date < end
    }

    /// Past sessions that were never done count as skipped; future ones are removed.
    private func retireActivePlans(now: Date) {
        let today = calendar.startOfDay(for: now)
        for plan in (try? activePlans()) ?? [] {
            plan.status = .superseded
            for session in plan.sessions where session.status == .planned {
                if session.scheduledDate < today {
                    session.status = .skipped
                } else {
                    context.delete(session)
                }
            }
        }
    }

    private func persist(_ week: PlannedWeek, now: Date) -> WorkoutPlan {
        let plan = WorkoutPlan(createdAt: now, weekStartDate: week.periodStart, generatorVersion: PlanGenerator.version, isReturnWeek: week.isReturnWeek)
        context.insert(plan)
        for planned in week.sessions {
            let session = WorkoutSession(scheduledDate: planned.date, plannedDurationMinutes: planned.plannedMinutes)
            plan.sessions.append(session)
            for (order, item) in planned.items.enumerated() {
                for setNumber in 1...max(1, item.sets) {
                    session.sets.append(WorkoutSet(
                        exerciseKey: item.exerciseKey,
                        variantKey: item.variantKey,
                        block: item.block,
                        orderIndex: order,
                        setNumber: setNumber,
                        targetReps: item.targetReps,
                        targetDurationSeconds: item.durationSeconds,
                        targetLoadKg: item.loadKg,
                        restSeconds: item.restSeconds
                    ))
                }
            }
        }
        return plan
    }

    // MARK: History

    func completedSessions() throws -> [WorkoutSession] {
        try context.fetch(FetchDescriptor<WorkoutSession>()).filter { $0.status == .completed }
    }

    func daysSinceLastWorkout(now: Date) throws -> Int? {
        guard let last = try completedSessions().compactMap(\.completedAt).max() else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day
    }

    func progressByExercise(for training: TrainingProfile) throws -> [String: ExerciseProgress] {
        let performances = try performancesByExercise()
        var result: [String: ExerciseProgress] = [:]
        for exercise in ExerciseCatalog.all {
            let maxLevel = availableMaxLevel(for: exercise, training: training)
            result[exercise.key] = ProgressionEngine.progress(for: exercise, maxLevel: maxLevel, history: performances[exercise.key] ?? [])
        }
        return result
    }

    /// Progress can't move past the highest level the user can actually do safely with their equipment.
    private func availableMaxLevel(for exercise: Exercise, training: TrainingProfile) -> Int {
        let safetyMax = SafetyEngine.maxLevel(for: exercise, constraints: training.constraints)
        let doable = exercise.variants
            .filter { $0.isAvailable(with: training.equipment) && SafetyEngine.isAllowed($0, constraints: training.constraints) }
            .map(\.level)
            .max() ?? 1
        return max(1, min(safetyMax, doable))
    }

    private func performancesByExercise() throws -> [String: [ExercisePerformance]] {
        var result: [String: [ExercisePerformance]] = [:]
        for session in try completedSessions() {
            let feedback = session.feedback
            let byExercise = Dictionary(grouping: session.sets, by: \.exerciseKey)
            for (key, sets) in byExercise {
                guard let first = sets.min(by: { $0.setNumber < $1.setNumber }),
                      let level = ExerciseCatalog.variant(first.variantKey)?.variant.level else { continue }
                result[key, default: []].append(ExercisePerformance(
                    date: session.completedAt ?? session.scheduledDate,
                    level: level,
                    targetReps: first.targetReps,
                    completedAllSets: sets.allSatisfy(\.isCompleted),
                    rpe: feedback?.rpe,
                    discomfort: feedback?.discomfort ?? .noDiscomfort,
                    loadKg: sets.compactMap(\.actualLoadKg).max()
                ))
            }
        }
        return result
    }

    // MARK: Session results

    func start(_ session: WorkoutSession, now: Date) throws {
        session.startedAt = session.startedAt ?? now
        session.status = .inProgress
        try context.save()
    }

    func completeSet(_ set: WorkoutSet, loadKg: Double?, now: Date) throws {
        set.actualReps = set.targetReps
        set.actualDurationSeconds = set.targetDurationSeconds
        set.actualLoadKg = loadKg
        set.completedAt = now
        try context.save()
    }

    /// Switches the remaining sets of an exercise to another variant (e.g. an easier one).
    func swapRemainingSets(of exerciseKey: String, in session: WorkoutSession, to variant: ExerciseVariant) throws {
        for set in session.sets where set.exerciseKey == exerciseKey && !set.isCompleted {
            set.variantKey = variant.key
            set.targetDurationSeconds = variant.prescription.durationSeconds
            if let range = variant.prescription.repRange {
                set.targetReps = min(max(set.targetReps ?? range.lowerBound, range.lowerBound), range.upperBound)
            } else {
                set.targetReps = nil
            }
            if !variant.tracksLoad {
                set.targetLoadKg = nil
            }
        }
        try context.save()
    }

    /// Saves end-of-session feedback and applies the safety engine's decision.
    @discardableResult
    func finish(_ session: WorkoutSession, feedback input: SessionFeedbackInput, note: String?, now: Date) throws -> SafetyDecision {
        let allDone = session.sets.allSatisfy(\.isCompleted)
        session.feedback = WorkoutFeedback(
            createdAt: now,
            rpe: input.rpe,
            discomfort: input.discomfort,
            discomfortRegions: input.discomfortRegions,
            dizzinessReported: input.dizzinessReported,
            completion: allDone ? .full : .partial,
            note: note
        )
        session.completedAt = now
        session.status = .completed
        let decision = SafetyEngine.evaluate(input)
        try apply(decision, now: now)
        return decision
    }

    /// Ends a session because the user doesn't feel well.
    @discardableResult
    func stop(_ session: WorkoutSession, reason: SafetyStopReason, now: Date) throws -> SafetyDecision {
        var regions: Set<BodyRegion> = []
        if case .pain(let painRegions) = reason { regions = painRegions }
        session.feedback = WorkoutFeedback(
            createdAt: now,
            rpe: nil,
            discomfort: regions.isEmpty ? .noDiscomfort : .newOrSharp,
            discomfortRegions: regions,
            dizzinessReported: reason == .warningSigns,
            completion: .stoppedEarly
        )
        session.status = reason == .generallyUnwell && session.startedAt == nil ? .skipped : .stoppedForSafety
        let decision = SafetyEngine.evaluate(reason)
        try apply(decision, now: now)
        return decision
    }

    private func apply(_ decision: SafetyDecision, now: Date) throws {
        let existing = Set(try activeConstraints().map { ConstraintSpec(kind: $0.kind, region: $0.bodyRegion) })
        let added = decision.newConstraints.filter { !existing.contains($0) }
        if let profile = try profile() {
            for spec in added {
                profile.safetyConstraints.append(SafetyConstraint(kind: spec.kind, bodyRegion: spec.region, source: .workoutFeedback, reportedAt: now))
            }
        }
        try context.save()
        if !added.isEmpty {
            _ = try regeneratePlan(now: now)
        }
    }
}
