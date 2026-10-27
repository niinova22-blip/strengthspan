import Foundation
import Testing
@testable import Strengthspan

@Suite("Progression engine")
struct ProgressionEngineTests {
    private let sitToStand = ExerciseCatalog.exercise("sitToStand")!
    private let tandem = ExerciseCatalog.exercise("tandemStance")!

    private func performance(
        day: Int,
        level: Int = 1,
        reps: Int? = 6,
        done: Bool = true,
        rpe: Int? = 6,
        discomfort: Discomfort = .noDiscomfort,
        load: Double? = nil
    ) -> ExercisePerformance {
        ExercisePerformance(
            date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
            level: level,
            targetReps: reps,
            completedAllSets: done,
            rpe: rpe,
            discomfort: discomfort,
            loadKg: load
        )
    }

    @Test func newUsersStartAtTheBottomOfLevelOne() {
        let progress = ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: [])
        #expect(progress == ExerciseProgress(level: 1, targetReps: 6))
    }

    @Test func oneGoodSessionIsNotEnough() {
        let progress = ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: [performance(day: 1)])
        #expect(progress.targetReps == 6)
    }

    @Test func twoGoodSessionsAddTwoReps() {
        let progress = ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: [performance(day: 1), performance(day: 3)])
        #expect(progress == ExerciseProgress(level: 1, targetReps: 8))
    }

    @Test func passingTheTopOfTheRangeMovesUpALevel() {
        let history = (1...6).map { performance(day: $0) }
        // 6 → 8 → 10 → level 2 at its lowest reps.
        #expect(ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: history) == ExerciseProgress(level: 2, targetReps: 8))
    }

    @Test func levelNeverExceedsTheAllowedMaximum() {
        let history = (1...12).map { performance(day: $0) } + (13...30).map { performance(day: $0, level: 2, reps: 8) }
        let progress = ProgressionEngine.progress(for: sitToStand, maxLevel: 2, history: history)
        #expect(progress.level == 2)
        #expect(progress.targetReps == 12)
    }

    @Test(arguments: [
        (rpe: 8 as Int?, done: true, discomfort: Discomfort.noDiscomfort),
        (rpe: nil, done: true, discomfort: .noDiscomfort),
        (rpe: 6, done: false, discomfort: .noDiscomfort),
        (rpe: 6, done: true, discomfort: .mildFamiliar),
    ])
    func noAdvanceUnlessEveryConditionHolds(rpe: Int?, done: Bool, discomfort: Discomfort) {
        let history = [performance(day: 1, done: done, rpe: rpe, discomfort: discomfort), performance(day: 3, done: done, rpe: rpe, discomfort: discomfort)]
        #expect(ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: history).targetReps == 6)
    }

    @Test func newPainResetsTheWindow() {
        let history = [performance(day: 1), performance(day: 2, discomfort: .newOrSharp), performance(day: 3)]
        #expect(ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: history).targetReps == 6)
    }

    @Test func twoVeryHardSessionsStepBack() {
        let up = (1...6).map { performance(day: $0) }
        let hard = [performance(day: 7, level: 2, reps: 8, rpe: 9), performance(day: 8, level: 2, reps: 8, rpe: 10)]
        #expect(ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: up + hard) == ExerciseProgress(level: 1, targetReps: 6))
    }

    @Test func timedExercisesProgressByLevel() {
        let history = [performance(day: 1, reps: nil), performance(day: 2, reps: nil)]
        #expect(ProgressionEngine.progress(for: tandem, maxLevel: 2, history: history) == ExerciseProgress(level: 2, targetReps: nil))
        #expect(ProgressionEngine.progress(for: tandem, maxLevel: 1, history: history).level == 1)
    }

    @Test func remembersTheLastUsedLoad() {
        let history = [performance(day: 1, load: 3), performance(day: 2, load: 4)]
        #expect(ProgressionEngine.progress(for: sitToStand, maxLevel: 4, history: history).lastLoadKg == 4)
    }
}
