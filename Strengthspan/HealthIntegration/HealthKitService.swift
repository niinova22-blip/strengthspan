import HealthKit

/// Writes completed Strengthspan workouts to Apple Health.
///
/// Minimum permission: the app only asks to *write* workouts and reads nothing. Health data is never
/// used for advertising, sold, or sent anywhere by Strengthspan.
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var canSaveWorkouts: Bool {
        Self.isAvailable && store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// Shows the system permission sheet if needed. Returns whether saving workouts is allowed.
    func requestWorkoutPermission() async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
        } catch {
            return false
        }
        return canSaveWorkouts
    }

    func saveStrengthWorkout(start: Date, end: Date) async throws {
        guard canSaveWorkouts, end > start else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        try await builder.beginCollection(at: start)
        try await builder.endCollection(at: end)
        _ = try await builder.finishWorkout()
    }
}
