import SwiftData

/// First shipped data model. Models are declared in extensions of this namespace
/// (`SchemaV1+*.swift`) and used through the aliases in `ModelAliases.swift`.
///
/// Once V1 ships, its models are frozen: changes go into a new `SchemaV2` plus a
/// migration stage in `StrengthspanMigrationPlan`.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            UserPreferences.self,
            SafetyConstraint.self,
            WorkoutPlan.self,
            WorkoutSession.self,
            WorkoutSet.self,
            WorkoutFeedback.self,
            AssessmentSession.self,
            AssessmentResult.self,
            CapacityMetric.self,
            ProgressSnapshot.self,
        ]
    }
}
