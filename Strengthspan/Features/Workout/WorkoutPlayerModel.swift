import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class WorkoutPlayerModel {
    enum Phase: Equatable {
        case checkIn
        case exercise
        case rest(secondsLeft: Int)
        case feedback
        case safetyCheck
        case stopped(SafetyDecision)
        case finished(SafetyDecision)
    }

    let session: WorkoutSession
    private let store: TrainingStore
    private let clock: any AppClock
    private let speech: SpeechCoach

    private(set) var phase: Phase
    private(set) var isPaused = false
    private(set) var timerSecondsLeft: Int?
    private(set) var isTimerRunning = false
    /// Increments on every completed set; drives haptics.
    private(set) var completedSetCount = 0
    var loadKg: Double = 0
    private var skippedExercises: Set<String> = []
    private var phaseBeforeSafetyCheck: Phase = .exercise
    private var ticker: Task<Void, Never>?

    init(session: WorkoutSession, store: TrainingStore, clock: any AppClock, voiceEnabled: Bool) {
        self.session = session
        self.store = store
        self.clock = clock
        self.speech = SpeechCoach(isEnabled: voiceEnabled)
        self.phase = session.startedAt == nil ? .checkIn : .exercise
        prepareCurrentSet()
    }

    // MARK: Derived state

    var orderedSets: [WorkoutSet] {
        session.sets.sorted { ($0.orderIndex, $0.setNumber) < ($1.orderIndex, $1.setNumber) }
    }

    private var remainingSets: [WorkoutSet] {
        orderedSets.filter { !$0.isCompleted && !skippedExercises.contains($0.exerciseKey) }
    }

    var currentSet: WorkoutSet? { remainingSets.first }

    var currentVariant: ExerciseVariant? {
        currentSet.flatMap { ExerciseCatalog.variant($0.variantKey)?.variant }
    }

    var nextVariant: ExerciseVariant? {
        remainingSets.dropFirst().first.flatMap { ExerciseCatalog.variant($0.variantKey)?.variant }
    }

    var setCountOfCurrentExercise: Int {
        guard let currentSet else { return 0 }
        return session.sets.filter { $0.orderIndex == currentSet.orderIndex }.count
    }

    var progressFraction: Double {
        let total = session.sets.count
        return total == 0 ? 0 : Double(session.sets.filter(\.isCompleted).count) / Double(total)
    }

    /// The next easier variant of the current exercise, if there is one.
    var easierVariant: ExerciseVariant? {
        guard let currentSet, let current = ExerciseCatalog.variant(currentSet.variantKey) else { return nil }
        return current.exercise.variants
            .filter { $0.level < current.variant.level && ($0.equipment == .bodyweightOnly || $0.equipment == current.variant.equipment) }
            .max { $0.level < $1.level }
    }

    // MARK: Actions

    func confirmCheckIn() {
        perform { try store.start(session, now: clock.now) }
        phase = .exercise
        prepareCurrentSet()
        announceCurrentSet()
    }

    func reportUnwell() {
        stopTicker()
        speech.stop()
        phaseBeforeSafetyCheck = phase
        phase = .safetyCheck
    }

    func cancelSafetyCheck() {
        phase = phaseBeforeSafetyCheck
        if case .rest = phase { startTicker() }
    }

    func stop(reason: SafetyStopReason) {
        if reason == .generallyUnwell && session.startedAt != nil {
            phase = .feedback
            return
        }
        let decision = perform { try store.stop(session, reason: reason, now: clock.now) } ?? .none
        phase = .stopped(decision)
    }

    func toggleTimer() {
        isTimerRunning.toggle()
        if isTimerRunning { startTicker() }
    }

    func completeSet() {
        guard let set = currentSet else { return }
        let load = currentVariant?.tracksLoad == true && loadKg > 0 ? loadKg : nil
        perform { try store.completeSet(set, loadKg: load, now: clock.now) }
        completedSetCount += 1
        isTimerRunning = false

        guard currentSet != nil else {
            finishExercises()
            return
        }
        if set.restSeconds > 0 {
            phase = .rest(secondsLeft: set.restSeconds)
            startTicker()
        } else {
            prepareCurrentSet()
            announceCurrentSet()
        }
    }

    func skipRest() {
        phase = .exercise
        prepareCurrentSet()
        announceCurrentSet()
    }

    func switchToEasier() {
        guard let set = currentSet, let easier = easierVariant else { return }
        perform { try store.swapRemainingSets(of: set.exerciseKey, in: session, to: easier) }
        prepareCurrentSet()
        announceCurrentSet()
    }

    func skipExercise() {
        guard let set = currentSet else { return }
        skippedExercises.insert(set.exerciseKey)
        isTimerRunning = false
        if currentSet == nil {
            finishExercises()
        } else {
            prepareCurrentSet()
            announceCurrentSet()
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused { speech.stop() }
    }

    func endEarly() {
        finishExercises()
    }

    func submitFeedback(_ input: SessionFeedbackInput, note: String?) {
        let decision = perform { try store.finish(session, feedback: input, note: note, now: clock.now) } ?? .none
        phase = .finished(decision)
    }

    func close() {
        stopTicker()
        speech.stop()
    }

    // MARK: Private

    private func finishExercises() {
        stopTicker()
        isTimerRunning = false
        phase = .feedback
        speech.say(String(localized: "player.announce.finished"))
    }

    private func prepareCurrentSet() {
        timerSecondsLeft = currentSet?.targetDurationSeconds
        isTimerRunning = false
        if let target = currentSet?.targetLoadKg {
            loadKg = target
        }
    }

    private func announceCurrentSet() {
        guard let set = currentSet, let variant = currentVariant else { return }
        speech.say(String(localized: "player.announce.set \(variant.localizedName) \(set.setNumber) \(setCountOfCurrentExercise)"))
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        guard !isPaused else { return }
        switch phase {
        case .rest(let secondsLeft):
            if secondsLeft <= 1 {
                stopTicker()
                skipRest()
            } else {
                phase = .rest(secondsLeft: secondsLeft - 1)
            }
        case .exercise where isTimerRunning:
            let left = (timerSecondsLeft ?? 0) - 1
            timerSecondsLeft = max(0, left)
            if left <= 0 {
                stopTicker()
                completeSet()
            }
        default:
            stopTicker()
        }
    }

    @discardableResult
    private func perform<T>(_ work: () throws -> T) -> T? {
        do {
            return try work()
        } catch {
            Logger.persistence.error("Workout update failed: \(String(describing: error))")
            return nil
        }
    }
}
