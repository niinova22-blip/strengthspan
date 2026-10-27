import Foundation
import Testing
@testable import Strengthspan

@Suite("Exercise catalog")
struct ExerciseCatalogTests {
    @Test func keysAreUnique() {
        let exerciseKeys = ExerciseCatalog.all.map(\.key)
        let variantKeys = ExerciseCatalog.all.flatMap(\.variants).map(\.key)
        #expect(Set(exerciseKeys).count == exerciseKeys.count)
        #expect(Set(variantKeys).count == variantKeys.count)
    }

    @Test func everyExerciseHasABodyweightLevelOne() {
        for exercise in ExerciseCatalog.all {
            #expect(exercise.variants.contains { $0.level == 1 && $0.equipment == .bodyweightOnly }, "\(exercise.key)")
        }
    }

    @Test func levelsHaveNoGaps() {
        for exercise in ExerciseCatalog.all {
            let levels = Set(exercise.variants.map(\.level))
            #expect(levels == Set(1...exercise.maxLevel), "\(exercise.key)")
        }
    }

    @Test func everyBlockHasAnOptionThatLoadsNoRegion() {
        for block in [WorkoutBlock.warmUp, .balanceControl, .cooldown] {
            #expect(ExerciseCatalog.all.contains { $0.block == block && $0.variants.contains { $0.loadedRegions.isEmpty } }, "\(block)")
        }
    }
}

@Suite("Plan generator")
struct PlanGeneratorTests {
    private let generator = PlanGenerator()
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return calendar
    }()
    /// Monday, 2 March 2026.
    private var monday: Date { calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 10))! }

    private func profile(
        length: SessionLength = .standard,
        equipment: Set<Equipment> = [.dumbbells, .resistanceBand],
        weekdays: Set<Int> = [2, 4, 6],
        goal: PrimaryGoal? = .buildStrength,
        screening: ScreeningOutcome = .cleared,
        constraints: [ConstraintSpec] = []
    ) -> TrainingProfile {
        TrainingProfile(sessionLength: length, equipment: equipment, preferredWeekdays: weekdays, goal: goal, screening: screening, constraints: constraints)
    }

    private func week(_ profile: TrainingProfile, progress: [String: ExerciseProgress] = [:], daysSince: Int? = nil) -> PlannedWeek? {
        guard case .plan(let week) = generator.generate(profile: profile, progress: progress, start: monday, daysSinceLastWorkout: daysSince, calendar: calendar) else {
            return nil
        }
        return week
    }

    @Test func blockedUsersGetNoPlan() {
        let outcome = generator.generate(profile: profile(screening: .professionalReviewRecommended), progress: [:], start: monday, daysSinceLastWorkout: nil, calendar: calendar)
        #expect(outcome == .blocked(.professionalReviewRecommended))
    }

    @Test func sameInputsGiveTheSamePlan() {
        #expect(week(profile()) == week(profile()))
    }

    @Test func sessionsFallOnTheChosenWeekdays() throws {
        let plan = try #require(week(profile(weekdays: [2, 5])))
        #expect(plan.sessions.map { calendar.component(.weekday, from: $0.date) } == [2, 5])
    }

    @Test func planStartsTodayEvenMidWeek() throws {
        let thursday = calendar.date(byAdding: .day, value: 3, to: monday)!
        guard case .plan(let plan) = generator.generate(profile: profile(), progress: [:], start: thursday, daysSinceLastWorkout: nil, calendar: calendar) else {
            Issue.record("expected a plan")
            return
        }
        // Mon/Wed/Fri within Thu…Wed: Fri, Mon, Wed.
        #expect(plan.sessions.map { calendar.component(.weekday, from: $0.date) } == [6, 2, 4])
        #expect(plan.sessions.allSatisfy { $0.date >= calendar.startOfDay(for: thursday) })
    }

    @Test(arguments: SessionLength.allCases)
    func estimatedDurationIsWithinFifteenPercent(length: SessionLength) throws {
        // Every day of the week, so every rotation combination is checked.
        let plan = try #require(week(profile(length: length, weekdays: Set(1...7))))
        for session in plan.sessions {
            let target = Double(length.rawValue * 60)
            let ratio = Double(session.estimatedSeconds) / target
            #expect((0.85...1.15).contains(ratio), "\(length): \(session.estimatedSeconds)s")
        }
    }

    @Test func everySessionHasAllFourBlocks() throws {
        let plan = try #require(week(profile()))
        for session in plan.sessions {
            #expect(Set(session.items.map(\.block)) == Set(WorkoutBlock.allCases))
        }
    }

    @Test func onlyOwnedEquipmentIsUsed() throws {
        let plan = try #require(week(profile(equipment: [], weekdays: Set(1...7)), progress: maxedOutProgress()))
        let variants = plan.sessions.flatMap(\.items).compactMap { ExerciseCatalog.variant($0.variantKey)?.variant }
        #expect(variants.allSatisfy { $0.equipment == .bodyweightOnly })
    }

    @Test func painfulRegionsAreExcluded() throws {
        let plan = try #require(week(profile(constraints: [ConstraintSpec(kind: .pain, region: .knee)])))
        let regions = plan.sessions.flatMap(\.items).compactMap { ExerciseCatalog.variant($0.variantKey)?.variant.loadedRegions }
        #expect(regions.allSatisfy { !$0.contains(.knee) })
    }

    @Test func mainExercisesRotateAcrossTheWeek() throws {
        let plan = try #require(week(profile(length: .short, weekdays: [2, 4, 6])))
        let mains = plan.sessions.map { $0.items.filter { $0.block == .mainStrength }.map(\.exerciseKey) }
        #expect(Set(mains.flatMap { $0 }).count > 2)
    }

    @Test func returnWeekIsLighter() throws {
        let progress = ["sitToStand": ExerciseProgress(level: 3, targetReps: 10)]
        let normal = try #require(week(profile(), progress: progress, daysSince: 2))
        let back = try #require(week(profile(), progress: progress, daysSince: 9))
        #expect(!normal.isReturnWeek)
        #expect(back.isReturnWeek)

        let normalSit = try #require(normal.sessions.flatMap(\.items).first { $0.exerciseKey == "sitToStand" })
        let backSit = try #require(back.sessions.flatMap(\.items).first { $0.exerciseKey == "sitToStand" })
        #expect(backSit.sets < normalSit.sets)
        #expect(ExerciseCatalog.variant(backSit.variantKey)!.variant.level < ExerciseCatalog.variant(normalSit.variantKey)!.variant.level)
    }

    @Test func balanceGoalAddsBalanceWork() throws {
        let strength = try #require(week(profile(goal: .buildStrength)))
        let balance = try #require(week(profile(goal: .improveBalance)))
        let count: (PlannedWeek) -> Int = { $0.sessions[0].items.filter { $0.block == .balanceControl }.count }
        #expect(count(balance) == count(strength) + 1)
    }

    @Test func balanceConcernKeepsBalanceWorkEasy() throws {
        let progress = ["tandemStance": ExerciseProgress(level: 2, targetReps: nil)]
        let plan = try #require(week(profile(constraints: [ConstraintSpec(kind: .balanceConcern, region: nil)]), progress: progress))
        let tandemItems = plan.sessions.flatMap(\.items).filter { $0.exerciseKey == "tandemStance" }
        #expect(tandemItems.allSatisfy { $0.variantKey == "tandem.semi" })
    }

    @Test func dumbbellWorkCarriesTheLastLoad() throws {
        let progress = ["sitToStand": ExerciseProgress(level: 4, targetReps: 8, lastLoadKg: 4)]
        let plan = try #require(week(profile(weekdays: Set(1...7)), progress: progress))
        let goblet = try #require(plan.sessions.flatMap(\.items).first { $0.variantKey == "sitToStand.goblet" })
        #expect(goblet.loadKg == 4)
    }

    private func maxedOutProgress() -> [String: ExerciseProgress] {
        Dictionary(uniqueKeysWithValues: ExerciseCatalog.all.map { ($0.key, ExerciseProgress(level: $0.maxLevel, targetReps: nil)) })
    }
}
