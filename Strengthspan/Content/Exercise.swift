import Foundation

enum MovementPattern: String, Codable, CaseIterable, Sendable {
    case locomotion
    case mobility
    case squat
    case hinge
    case push
    case pull
    case overhead
    case calf
    case hipAbduction
    case balance
    case stretch
    case breathing
}

enum Prescription: Hashable, Sendable {
    case reps(ClosedRange<Int>)
    case timed(seconds: Int)

    var repRange: ClosedRange<Int>? {
        if case .reps(let range) = self { return range }
        return nil
    }

    var durationSeconds: Int? {
        if case .timed(let seconds) = self { return seconds }
        return nil
    }
}

/// One concrete way to perform an exercise. Variants of an exercise form a difficulty ladder by `level`.
struct ExerciseVariant: Hashable, Sendable, Identifiable {
    let key: String
    let level: Int
    let equipment: Equipment
    let prescription: Prescription
    /// Body regions that carry meaningful load; used by the safety engine to respect reported pain.
    let loadedRegions: Set<BodyRegion>
    /// The user holds a chair, counter or wall for balance.
    let usesSupport: Bool

    var id: String { key }
    /// Localization keys for the display name and the how-to text.
    var nameKey: String { "exercise.\(key)" }
    var instructionKey: String { "exercise.\(key).how" }
    /// Only dumbbell work records a weight in kilograms.
    var tracksLoad: Bool { equipment == .dumbbells }

    func isAvailable(with equipment: Set<Equipment>) -> Bool {
        self.equipment == .bodyweightOnly || equipment.contains(self.equipment)
    }
}

struct Exercise: Hashable, Sendable, Identifiable {
    let key: String
    let pattern: MovementPattern
    let dimension: CapacityDimension
    let block: WorkoutBlock
    /// Ordered by level, lowest first.
    let variants: [ExerciseVariant]

    var id: String { key }

    var maxLevel: Int { variants.map(\.level).max() ?? 1 }

    /// The reference variant for a level, used for rep ranges during progression.
    func representativeVariant(level: Int) -> ExerciseVariant? {
        variants.first { $0.level == level }
    }
}
