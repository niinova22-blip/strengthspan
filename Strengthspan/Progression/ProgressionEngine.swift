import Foundation

/// One session's result for one exercise, derived from workout history.
struct ExercisePerformance: Equatable, Sendable {
    let date: Date
    let level: Int
    let targetReps: Int?
    let completedAllSets: Bool
    let rpe: Int?
    let discomfort: Discomfort
    let loadKg: Double?
}

/// Where the user currently is on an exercise's difficulty ladder.
struct ExerciseProgress: Equatable, Sendable {
    var level: Int
    /// `nil` for timed exercises.
    var targetReps: Int?
    var lastLoadKg: Double?
}

/// Deterministic progression (docs/05 §4). Progress is recomputed from history every time,
/// so there is no hidden state to drift or migrate.
///
/// - Advance (SAF-04): two consecutive sessions at the current level, all sets done, RPE ≤ 7,
///   no discomfort → +2 reps; past the top of the range → next level at its lowest reps.
///   Only one variable changes at a time.
/// - Regress: two consecutive sessions with RPE ≥ 9 → back to the bottom of the range,
///   or one level down if already there.
/// - Hold (SAF-01): new or sharp discomfort resets the window.
enum ProgressionEngine {
    static let advanceMaxRPE = 7
    static let regressMinRPE = 9
    static let repStep = 2

    static func initialProgress(for exercise: Exercise) -> ExerciseProgress {
        ExerciseProgress(level: 1, targetReps: exercise.representativeVariant(level: 1)?.prescription.repRange?.lowerBound)
    }

    static func progress(for exercise: Exercise, maxLevel: Int, history: [ExercisePerformance]) -> ExerciseProgress {
        var state = initialProgress(for: exercise)
        var window: [ExercisePerformance] = []

        for performance in history.sorted(by: { $0.date < $1.date }) {
            if let load = performance.loadKg {
                state.lastLoadKg = load
            }
            guard performance.level == state.level else { continue }

            if performance.discomfort == .newOrSharp {
                window.removeAll()
                continue
            }
            window.append(performance)
            let lastTwo = window.suffix(2)
            guard lastTwo.count == 2 else { continue }

            if lastTwo.allSatisfy({ ($0.rpe ?? 0) >= regressMinRPE }) {
                regress(&state, exercise: exercise)
                window.removeAll()
            } else if lastTwo.allSatisfy(isReadyToAdvance) {
                advance(&state, exercise: exercise, maxLevel: maxLevel)
                window.removeAll()
            }
        }

        return clamped(state, exercise: exercise, maxLevel: maxLevel)
    }

    private static func isReadyToAdvance(_ performance: ExercisePerformance) -> Bool {
        guard let rpe = performance.rpe else { return false }
        return performance.completedAllSets && rpe <= advanceMaxRPE && performance.discomfort == .noDiscomfort
    }

    private static func advance(_ state: inout ExerciseProgress, exercise: Exercise, maxLevel: Int) {
        let range = exercise.representativeVariant(level: state.level)?.prescription.repRange
        if let range, let reps = state.targetReps, reps + repStep <= range.upperBound {
            state.targetReps = reps + repStep
            return
        }
        let nextLevel = state.level + 1
        guard nextLevel <= maxLevel, let next = exercise.representativeVariant(level: nextLevel) else {
            if let range { state.targetReps = range.upperBound }
            return
        }
        state.level = nextLevel
        state.targetReps = next.prescription.repRange?.lowerBound
    }

    private static func regress(_ state: inout ExerciseProgress, exercise: Exercise) {
        let range = exercise.representativeVariant(level: state.level)?.prescription.repRange
        if let range, let reps = state.targetReps, reps > range.lowerBound {
            state.targetReps = range.lowerBound
            return
        }
        guard state.level > 1, let previous = exercise.representativeVariant(level: state.level - 1) else { return }
        state.level -= 1
        state.targetReps = previous.prescription.repRange?.lowerBound
    }

    private static func clamped(_ state: ExerciseProgress, exercise: Exercise, maxLevel: Int) -> ExerciseProgress {
        guard state.level > maxLevel, let variant = exercise.representativeVariant(level: max(1, maxLevel)) else {
            return state
        }
        return ExerciseProgress(level: variant.level, targetReps: variant.prescription.repRange?.lowerBound, lastLoadKg: state.lastLoadKg)
    }
}
