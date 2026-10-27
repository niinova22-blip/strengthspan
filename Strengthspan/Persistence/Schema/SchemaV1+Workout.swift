import Foundation
import SwiftData

extension SchemaV1 {
    /// One week of planned sessions produced by a specific generator version.
    @Model
    final class WorkoutPlan {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var weekStartDate: Date
        var generatorVersion: String
        var statusRaw: String
        /// A lighter week after a break (SAF-07).
        var isReturnWeek: Bool = false

        @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)
        var sessions: [WorkoutSession] = []

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            weekStartDate: Date,
            generatorVersion: String,
            status: PlanStatus = .active,
            isReturnWeek: Bool = false
        ) {
            self.id = id
            self.createdAt = createdAt
            self.weekStartDate = weekStartDate
            self.generatorVersion = generatorVersion
            self.statusRaw = status.rawValue
            self.isReturnWeek = isReturnWeek
        }

        var status: PlanStatus {
            get { PlanStatus(rawValue: statusRaw) ?? .archived }
            set { statusRaw = newValue.rawValue }
        }
    }

    @Model
    final class WorkoutSession {
        @Attribute(.unique) var id: UUID
        var scheduledDate: Date
        var plannedDurationMinutes: Int
        var startedAt: Date?
        var completedAt: Date?
        var statusRaw: String
        /// Set once the session has been written to Apple Health, so it is never written twice.
        var exportedToHealthAt: Date?
        var plan: WorkoutPlan?

        @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
        var sets: [WorkoutSet] = []

        @Relationship(deleteRule: .cascade, inverse: \WorkoutFeedback.session)
        var feedback: WorkoutFeedback?

        init(
            id: UUID = UUID(),
            scheduledDate: Date,
            plannedDurationMinutes: Int,
            status: SessionStatus = .planned
        ) {
            self.id = id
            self.scheduledDate = scheduledDate
            self.plannedDurationMinutes = plannedDurationMinutes
            self.statusRaw = status.rawValue
        }

        var status: SessionStatus {
            get { SessionStatus(rawValue: statusRaw) ?? .planned }
            set { statusRaw = newValue.rawValue }
        }
    }

    /// One set of one exercise. Exercises are referenced by stable catalog keys rather than
    /// relationships so history stays meaningful when the bundled catalog changes.
    @Model
    final class WorkoutSet {
        @Attribute(.unique) var id: UUID
        var exerciseKey: String
        var variantKey: String
        var blockRaw: String
        var orderIndex: Int
        var setNumber: Int
        var targetReps: Int?
        var targetDurationSeconds: Int?
        /// Loads are always stored in kilograms and formatted for the user's locale.
        var targetLoadKg: Double?
        var actualReps: Int?
        var actualDurationSeconds: Int?
        var actualLoadKg: Double?
        var restSeconds: Int
        var completedAt: Date?
        var session: WorkoutSession?

        init(
            id: UUID = UUID(),
            exerciseKey: String,
            variantKey: String,
            block: WorkoutBlock,
            orderIndex: Int,
            setNumber: Int,
            targetReps: Int? = nil,
            targetDurationSeconds: Int? = nil,
            targetLoadKg: Double? = nil,
            restSeconds: Int
        ) {
            self.id = id
            self.exerciseKey = exerciseKey
            self.variantKey = variantKey
            self.blockRaw = block.rawValue
            self.orderIndex = orderIndex
            self.setNumber = setNumber
            self.targetReps = targetReps
            self.targetDurationSeconds = targetDurationSeconds
            self.targetLoadKg = targetLoadKg
            self.restSeconds = restSeconds
        }

        var block: WorkoutBlock {
            WorkoutBlock(rawValue: blockRaw) ?? .mainStrength
        }

        var isCompleted: Bool { completedAt != nil }
    }

    /// End-of-session report. This is the main input for progression and safety decisions.
    @Model
    final class WorkoutFeedback {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        /// Perceived exertion on a 1–10 scale.
        var rpe: Int?
        var discomfortRaw: String
        var discomfortRegionsRaw: [String]
        var dizzinessReported: Bool
        var completionRaw: String
        var note: String?
        var session: WorkoutSession?

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            rpe: Int?,
            discomfort: Discomfort,
            discomfortRegions: Set<BodyRegion> = [],
            dizzinessReported: Bool,
            completion: CompletionLevel,
            note: String? = nil
        ) {
            self.id = id
            self.createdAt = createdAt
            self.rpe = rpe.map { min(max($0, 1), 10) }
            self.discomfortRaw = discomfort.rawValue
            self.discomfortRegionsRaw = discomfortRegions.map(\.rawValue).sorted()
            self.dizzinessReported = dizzinessReported
            self.completionRaw = completion.rawValue
            self.note = note
        }

        /// Unknown values are read as `.newOrSharp` so the safety engine errs on the side of caution.
        var discomfort: Discomfort {
            Discomfort(rawValue: discomfortRaw) ?? .newOrSharp
        }

        var discomfortRegions: Set<BodyRegion> {
            Set(discomfortRegionsRaw.compactMap(BodyRegion.init(rawValue:)))
        }

        var completion: CompletionLevel {
            CompletionLevel(rawValue: completionRaw) ?? .partial
        }
    }
}
