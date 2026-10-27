// The app always works with the latest schema through these aliases.
// When SchemaV2 is introduced, point the aliases at it and add a migration stage.

typealias UserProfile = SchemaV1.UserProfile
typealias UserPreferences = SchemaV1.UserPreferences
typealias SafetyConstraint = SchemaV1.SafetyConstraint
typealias WorkoutPlan = SchemaV1.WorkoutPlan
typealias WorkoutSession = SchemaV1.WorkoutSession
typealias WorkoutSet = SchemaV1.WorkoutSet
typealias WorkoutFeedback = SchemaV1.WorkoutFeedback
typealias AssessmentSession = SchemaV1.AssessmentSession
typealias AssessmentResult = SchemaV1.AssessmentResult
typealias CapacityMetric = SchemaV1.CapacityMetric
typealias ProgressSnapshot = SchemaV1.ProgressSnapshot
