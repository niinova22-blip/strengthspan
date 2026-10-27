import Foundation

/// Everything the generator needs to know about the user, as plain values.
struct TrainingProfile: Equatable, Sendable {
    var sessionLength: SessionLength
    var equipment: Set<Equipment>
    /// `Calendar` weekday numbers (1 = Sunday ... 7 = Saturday).
    var preferredWeekdays: Set<Int>
    var goal: PrimaryGoal?
    var screening: ScreeningOutcome
    var constraints: [ConstraintSpec]
}

struct PlannedItem: Equatable, Sendable {
    let exerciseKey: String
    let variantKey: String
    let block: WorkoutBlock
    let sets: Int
    let targetReps: Int?
    let durationSeconds: Int?
    let loadKg: Double?
    let restSeconds: Int
}

struct PlannedSession: Equatable, Sendable {
    let date: Date
    let plannedMinutes: Int
    let items: [PlannedItem]
    let estimatedSeconds: Int
}

struct PlannedWeek: Equatable, Sendable {
    let periodStart: Date
    let isReturnWeek: Bool
    let sessions: [PlannedSession]
}

enum PlanOutcome: Equatable, Sendable {
    case plan(PlannedWeek)
    case blocked(PlanBlockReason)
}

/// Builds a seven-day plan from deterministic rules. The same inputs always produce the same plan.
struct PlanGenerator: Sendable {
    static let version = "plan-1"
    static let periodDays = 7
    /// SAF-07: a break this long triggers a lighter return week.
    static let returnWeekThresholdDays = 7
    /// Controlled tempo for people new to strength work: ~2 s up, ~3 s down.
    static let secondsPerRep = 5
    static let transitionSeconds = 20
    static let maxOverrun = 0.10
    /// Used when the user has not picked any days.
    static let defaultWeekdays: Set<Int> = [2, 4, 6]

    struct Template: Equatable, Sendable {
        let warmUps: Int
        let mains: Int
        let mainSets: Int
        let mainRestSeconds: Int
        let balance: Int
        let balanceSets: Int
        let balanceRestSeconds: Int
        let cooldowns: Int
    }

    static func template(for length: SessionLength, goal: PrimaryGoal?) -> Template {
        let extraBalance = goal == .improveBalance ? 1 : 0
        return switch length {
        case .short:
            Template(warmUps: 1, mains: 3, mainSets: 2, mainRestSeconds: 30, balance: 1 + extraBalance, balanceSets: 2, balanceRestSeconds: 30, cooldowns: 1)
        case .standard:
            Template(warmUps: 2, mains: 5, mainSets: 2, mainRestSeconds: 60, balance: 1 + extraBalance, balanceSets: 2, balanceRestSeconds: 30, cooldowns: 2)
        case .long:
            Template(warmUps: 2, mains: 5, mainSets: 3, mainRestSeconds: 60, balance: 2 + extraBalance, balanceSets: 2, balanceRestSeconds: 30, cooldowns: 3)
        }
    }

    var catalog: [Exercise] = ExerciseCatalog.all

    /// - Parameters:
    ///   - progress: current progress per exercise key; missing exercises start at level 1.
    ///   - start: first day of the plan period.
    ///   - daysSinceLastWorkout: `nil` if the user has never completed a workout.
    func generate(
        profile: TrainingProfile,
        progress: [String: ExerciseProgress],
        start: Date,
        daysSinceLastWorkout: Int?,
        calendar: Calendar
    ) -> PlanOutcome {
        if case .blocked(let reason) = SafetyEngine.planPermission(screening: profile.screening, constraints: profile.constraints) {
            return .blocked(reason)
        }

        let isReturnWeek = (daysSinceLastWorkout ?? 0) >= Self.returnWeekThresholdDays
        let periodStart = calendar.startOfDay(for: start)
        let weekdays = profile.preferredWeekdays.isEmpty ? Self.defaultWeekdays : profile.preferredWeekdays
        let dates = (0..<Self.periodDays).compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: periodStart) else { return nil }
            return weekdays.contains(calendar.component(.weekday, from: date)) ? date : nil
        }

        let template = Self.template(for: profile.sessionLength, goal: profile.goal)
        let sessions = dates.enumerated().map { index, date in
            makeSession(
                index: index,
                date: date,
                profile: profile,
                template: template,
                progress: progress,
                isReturnWeek: isReturnWeek
            )
        }
        return .plan(PlannedWeek(periodStart: periodStart, isReturnWeek: isReturnWeek, sessions: sessions))
    }

    // MARK: - Session assembly

    private func makeSession(
        index: Int,
        date: Date,
        profile: TrainingProfile,
        template: Template,
        progress: [String: ExerciseProgress],
        isReturnWeek: Bool
    ) -> PlannedSession {
        let mainSets = isReturnWeek ? max(1, template.mainSets - 1) : template.mainSets
        let blocks: [(WorkoutBlock, Int, Int, Int)] = [
            (.warmUp, template.warmUps, 1, 0),
            (.mainStrength, template.mains, mainSets, template.mainRestSeconds),
            (.balanceControl, template.balance, template.balanceSets, template.balanceRestSeconds),
            (.cooldown, template.cooldowns, 1, 0),
        ]

        var items: [PlannedItem] = []
        for (block, count, sets, rest) in blocks {
            let candidates = catalog.filter { $0.block == block }.compactMap { exercise -> (Exercise, ExerciseVariant, ExerciseProgress)? in
                let state = effectiveProgress(for: exercise, profile: profile, progress: progress, isReturnWeek: isReturnWeek)
                guard let variant = chooseVariant(for: exercise, level: state.level, profile: profile) else { return nil }
                return (exercise, variant, state)
            }
            for (exercise, variant, state) in rotate(candidates, sessionIndex: index, count: count) {
                items.append(item(exercise: exercise, variant: variant, state: state, block: block, sets: sets, rest: rest))
            }
        }

        items = trimmed(items, targetSeconds: profile.sessionLength.rawValue * 60)
        return PlannedSession(
            date: date,
            plannedMinutes: profile.sessionLength.rawValue,
            items: items,
            estimatedSeconds: Self.estimatedSeconds(for: items)
        )
    }

    /// Keeps the session within `maxOverrun` of the chosen length by dropping main sets from the end.
    private func trimmed(_ items: [PlannedItem], targetSeconds: Int) -> [PlannedItem] {
        var items = items
        let limit = Double(targetSeconds) * (1 + Self.maxOverrun)
        while Double(Self.estimatedSeconds(for: items)) > limit,
              let index = items.lastIndex(where: { $0.block == .mainStrength && $0.sets > 1 }) {
            items[index] = items[index].withSets(items[index].sets - 1)
        }
        return items
    }

    private func effectiveProgress(
        for exercise: Exercise,
        profile: TrainingProfile,
        progress: [String: ExerciseProgress],
        isReturnWeek: Bool
    ) -> ExerciseProgress {
        var state = progress[exercise.key] ?? ProgressionEngine.initialProgress(for: exercise)
        let maxLevel = SafetyEngine.maxLevel(for: exercise, constraints: profile.constraints)
        if isReturnWeek {
            state.level -= 1
        }
        state.level = min(max(1, state.level), maxLevel)
        return state
    }

    /// Highest allowed variant at or below `level` that the user has equipment for.
    /// At equal level, equipment-based variants are preferred over bodyweight ones.
    func chooseVariant(for exercise: Exercise, level: Int, profile: TrainingProfile) -> ExerciseVariant? {
        exercise.variants
            .filter { $0.level <= level && $0.isAvailable(with: profile.equipment) && SafetyEngine.isAllowed($0, constraints: profile.constraints) }
            .max { lhs, rhs in
                if lhs.level != rhs.level { return lhs.level < rhs.level }
                return lhs.equipment == .bodyweightOnly && rhs.equipment != .bodyweightOnly
            }
    }

    private func rotate<T>(_ candidates: [T], sessionIndex: Int, count: Int) -> [T] {
        guard !candidates.isEmpty, count > 0 else { return [] }
        let take = min(count, candidates.count)
        let offset = (sessionIndex * take) % candidates.count
        return (0..<take).map { candidates[(offset + $0) % candidates.count] }
    }

    private func item(
        exercise: Exercise,
        variant: ExerciseVariant,
        state: ExerciseProgress,
        block: WorkoutBlock,
        sets: Int,
        rest: Int
    ) -> PlannedItem {
        var reps: Int?
        if let range = variant.prescription.repRange {
            let target = variant.level == state.level ? (state.targetReps ?? range.lowerBound) : range.lowerBound
            reps = min(max(target, range.lowerBound), range.upperBound)
        }
        return PlannedItem(
            exerciseKey: exercise.key,
            variantKey: variant.key,
            block: block,
            sets: sets,
            targetReps: reps,
            durationSeconds: variant.prescription.durationSeconds,
            loadKg: variant.tracksLoad ? state.lastLoadKg : nil,
            restSeconds: rest
        )
    }

    static func estimatedSeconds(for item: PlannedItem) -> Int {
        let work = item.durationSeconds ?? (item.targetReps ?? 0) * secondsPerRep
        return transitionSeconds + item.sets * work + max(0, item.sets - 1) * item.restSeconds
    }

    static func estimatedSeconds(for items: [PlannedItem]) -> Int {
        items.reduce(0) { $0 + estimatedSeconds(for: $1) }
    }
}

extension PlannedItem {
    func withSets(_ sets: Int) -> PlannedItem {
        PlannedItem(
            exerciseKey: exerciseKey,
            variantKey: variantKey,
            block: block,
            sets: sets,
            targetReps: targetReps,
            durationSeconds: durationSeconds,
            loadKg: loadKg,
            restSeconds: restSeconds
        )
    }
}
