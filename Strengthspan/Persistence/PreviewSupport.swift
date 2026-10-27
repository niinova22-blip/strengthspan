#if DEBUG
import Foundation
import SwiftData

/// Sample data for Xcode Previews only. Compiled out of release builds and never shown to users.
@MainActor
enum PreviewSupport {
    static func container(populated: Bool) -> ModelContainer {
        do {
            let container = try PersistenceController.makeContainer(inMemory: true)
            if populated {
                insertSampleData(into: container.mainContext)
            }
            return container
        } catch {
            fatalError("Preview container could not be created: \(error)")
        }
    }

    private static func insertSampleData(into context: ModelContext) {
        let assessedAt = Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now

        let session = AssessmentSession(
            startedAt: assessedAt,
            isBaseline: true,
            deviceModel: "preview",
            appVersion: "preview"
        )
        session.markCompleted(at: assessedAt)
        context.insert(session)

        let strength = CapacityMetric(
            computedAt: assessedAt,
            dimension: .strength,
            score: 48,
            reliability: .moderate,
            scoringModelVersion: "preview"
        )
        strength.sourceSession = session
        context.insert(strength)

        let todaySession = WorkoutSession(scheduledDate: .now, plannedDurationMinutes: 20)
        context.insert(todaySession)
    }
}
#endif
