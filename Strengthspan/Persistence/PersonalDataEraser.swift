import SwiftData

/// Permanently removes all of the user's personal data from the local store.
struct PersonalDataEraser {
    let context: ModelContext

    func eraseAll() throws {
        do {
            // Children before parents, so no object is deleted twice through a cascade.
            try deleteAll(WorkoutSet.self)
            try deleteAll(WorkoutFeedback.self)
            try deleteAll(WorkoutSession.self)
            try deleteAll(WorkoutPlan.self)
            try deleteAll(CapacityMetric.self)
            try deleteAll(AssessmentResult.self)
            try deleteAll(AssessmentSession.self)
            try deleteAll(ProgressSnapshot.self)
            try deleteAll(SafetyConstraint.self)
            try deleteAll(UserPreferences.self)
            try deleteAll(UserProfile.self)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func deleteAll<Model: PersistentModel>(_ type: Model.Type) throws {
        for model in try context.fetch(FetchDescriptor<Model>()) {
            context.delete(model)
        }
    }
}
