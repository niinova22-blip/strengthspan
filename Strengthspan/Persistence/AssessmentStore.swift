import Foundation
import SwiftData
import UIKit

/// Saves capacity checks and derives the capacity map and progress figures from them.
@MainActor
struct AssessmentStore {
    let context: ModelContext
    var calendar: Calendar = .current

    func completedSessions() throws -> [AssessmentSession] {
        try context.fetch(FetchDescriptor<AssessmentSession>())
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt) }
    }

    func startSession(now: Date) throws -> AssessmentSession {
        let session = AssessmentSession(
            startedAt: now,
            isBaseline: try completedSessions().isEmpty,
            deviceModel: UIDevice.current.model,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
        context.insert(session)
        try context.save()
        return session
    }

    func record(
        _ outcome: MeasurementOutcome,
        for definition: AssessmentDefinition,
        method: MeasurementMethod,
        in session: AssessmentSession,
        now: Date
    ) throws {
        session.results.append(AssessmentResult(
            recordedAt: now,
            assessmentKey: definition.key,
            definitionVersion: definition.version,
            method: method,
            status: outcome.status,
            value: outcome.value,
            unit: outcome.unit,
            durationSeconds: outcome.durationSeconds,
            reliability: outcome.reliability,
            qualityFlags: outcome.qualityFlags,
            usedSupport: definition.usesSupport,
            setupVariant: definition.setupVariant
        ))
        try context.save()
    }

    func recordSkipped(_ definition: AssessmentDefinition, in session: AssessmentSession, now: Date) throws {
        try record(
            MeasurementOutcome(status: .skipped, value: nil, unit: definition.unit(for: .manual), reliability: .insufficient, qualityFlags: [], durationSeconds: 0),
            for: definition,
            method: .manual,
            in: session,
            now: now
        )
    }

    /// Completes the session and writes one capacity metric per dimension from its primary test.
    func complete(_ session: AssessmentSession, now: Date) throws {
        session.markCompleted(at: now)
        for dimension in CapacityDimension.allCases {
            let definition = AssessmentCatalog.primary(for: dimension)
            guard let result = session.results.last(where: { $0.assessmentKey == definition.key && $0.status == .valid }),
                  let method = result.method, let unit = result.unit else { continue }
            session.metrics.append(CapacityMetric(
                computedAt: now,
                dimension: dimension,
                assessmentKey: definition.key,
                value: result.value,
                unit: unit,
                method: method,
                reliability: result.reliability
            ))
        }
        try context.save()
    }

    /// Removes an unfinished session (the user left the flow without saving).
    func discard(_ session: AssessmentSession) throws {
        context.delete(session)
        try context.save()
    }

    func snapshots(for key: String) throws -> [ResultSnapshot] {
        try completedSessions().flatMap(\.results).filter { $0.assessmentKey == key }.compactMap(\.snapshot)
    }
}

extension AssessmentResult {
    var snapshot: ResultSnapshot? {
        guard let method, let unit else { return nil }
        return ResultSnapshot(
            date: recordedAt,
            assessmentKey: assessmentKey,
            definitionVersion: definitionVersion,
            method: method,
            status: status,
            value: value,
            unit: unit,
            reliability: reliability,
            usedSupport: usedSupport,
            setupVariant: setupVariant
        )
    }
}
