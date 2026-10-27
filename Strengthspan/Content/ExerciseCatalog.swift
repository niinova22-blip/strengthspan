import Foundation

/// Bundled exercise library. Standing or chair-based movements only: no floor transitions,
/// no unsupported single-leg work. Keys are stored in workout history and must never change.
enum ExerciseCatalog {
    static let version = 1

    static let all: [Exercise] = [
        // MARK: Warm-up
        Exercise(key: "march", pattern: .locomotion, dimension: .mobility, block: .warmUp, variants: [
            variant("march.inPlace", 1, .timed(seconds: 60), [], support: true),
        ]),
        Exercise(key: "armCircles", pattern: .mobility, dimension: .mobility, block: .warmUp, variants: [
            variant("armCircles.standing", 1, .timed(seconds: 30), [.shoulder]),
        ]),
        Exercise(key: "hipCircles", pattern: .mobility, dimension: .mobility, block: .warmUp, variants: [
            variant("hipCircles.supported", 1, .timed(seconds: 30), [.hip], support: true),
        ]),

        // MARK: Main strength
        Exercise(key: "sitToStand", pattern: .squat, dimension: .strength, block: .mainStrength, variants: [
            variant("sitToStand.withHands", 1, .reps(6...10), [.knee, .hip]),
            variant("sitToStand.armsCrossed", 2, .reps(8...12), [.knee, .hip]),
            variant("sitToStand.slowLower", 3, .reps(8...12), [.knee, .hip]),
            variant("sitToStand.goblet", 4, .reps(8...12), [.knee, .hip], equipment: .dumbbells),
        ]),
        Exercise(key: "pushUp", pattern: .push, dimension: .strength, block: .mainStrength, variants: [
            variant("pushUp.wall", 1, .reps(8...12), [.shoulder, .wristHand]),
            variant("pushUp.counter", 2, .reps(8...12), [.shoulder, .wristHand]),
            variant("pushUp.counterSlow", 3, .reps(8...12), [.shoulder, .wristHand]),
        ]),
        Exercise(key: "row", pattern: .pull, dimension: .strength, block: .mainStrength, variants: [
            variant("row.shoulderSqueeze", 1, .reps(10...15), [.shoulder]),
            variant("row.band", 2, .reps(10...15), [.shoulder, .back], equipment: .resistanceBand),
            variant("row.dumbbellSupported", 2, .reps(8...12), [.shoulder, .back], equipment: .dumbbells, support: true),
        ]),
        Exercise(key: "hinge", pattern: .hinge, dimension: .strength, block: .mainStrength, variants: [
            variant("hinge.handsOnThighs", 1, .reps(8...12), [.back, .hip]),
            variant("hinge.slowTempo", 2, .reps(8...12), [.back, .hip]),
            variant("hinge.dumbbell", 3, .reps(8...12), [.back, .hip], equipment: .dumbbells),
        ]),
        Exercise(key: "calfRaise", pattern: .calf, dimension: .strength, block: .mainStrength, variants: [
            variant("calfRaise.supported", 1, .reps(10...15), [.ankleFoot], support: true),
            variant("calfRaise.pause", 2, .reps(10...15), [.ankleFoot], support: true),
            variant("calfRaise.dumbbell", 3, .reps(10...15), [.ankleFoot], equipment: .dumbbells, support: true),
        ]),
        Exercise(key: "overhead", pattern: .overhead, dimension: .strength, block: .mainStrength, variants: [
            variant("overhead.wallSlide", 1, .reps(8...12), [.shoulder]),
            variant("overhead.band", 2, .reps(8...12), [.shoulder], equipment: .resistanceBand),
            variant("overhead.dumbbellSeated", 2, .reps(8...12), [.shoulder], equipment: .dumbbells),
        ]),
        Exercise(key: "sideLegRaise", pattern: .hipAbduction, dimension: .movementControl, block: .mainStrength, variants: [
            variant("sideLegRaise.supported", 1, .reps(8...12), [.hip], support: true),
            variant("sideLegRaise.band", 2, .reps(8...12), [.hip], equipment: .resistanceBand, support: true),
        ]),

        // MARK: Balance & movement control
        Exercise(key: "weightShift", pattern: .balance, dimension: .balance, block: .balanceControl, variants: [
            variant("weightShift.supported", 1, .timed(seconds: 30), [], support: true),
        ]),
        Exercise(key: "tandemStance", pattern: .balance, dimension: .balance, block: .balanceControl, variants: [
            variant("tandem.semi", 1, .timed(seconds: 20), [.ankleFoot], support: true),
            variant("tandem.full", 2, .timed(seconds: 30), [.ankleFoot], support: true),
        ]),
        Exercise(key: "heelToeWalk", pattern: .balance, dimension: .balance, block: .balanceControl, variants: [
            variant("heelToe.counter", 1, .timed(seconds: 30), [.ankleFoot, .knee], support: true),
        ]),
        Exercise(key: "stepTap", pattern: .balance, dimension: .movementControl, block: .balanceControl, variants: [
            variant("stepTap.supported", 1, .timed(seconds: 30), [.knee, .hip], support: true),
        ]),

        // MARK: Cooldown
        Exercise(key: "calfStretch", pattern: .stretch, dimension: .mobility, block: .cooldown, variants: [
            variant("stretch.calfWall", 1, .timed(seconds: 30), [.ankleFoot], support: true),
        ]),
        Exercise(key: "chestOpener", pattern: .stretch, dimension: .mobility, block: .cooldown, variants: [
            variant("stretch.chestOpener", 1, .timed(seconds: 30), [.shoulder]),
        ]),
        Exercise(key: "hamstringStretch", pattern: .stretch, dimension: .mobility, block: .cooldown, variants: [
            variant("stretch.hamstringSeated", 1, .timed(seconds: 30), [.back]),
        ]),
        Exercise(key: "breathing", pattern: .breathing, dimension: .movementControl, block: .cooldown, variants: [
            variant("breathing.slow", 1, .timed(seconds: 60), []),
        ]),
    ]

    private static let byExerciseKey: [String: Exercise] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })

    private static let byVariantKey: [String: (Exercise, ExerciseVariant)] = Dictionary(
        uniqueKeysWithValues: all.flatMap { exercise in exercise.variants.map { ($0.key, (exercise, $0)) } }
    )

    static func exercise(_ key: String) -> Exercise? {
        byExerciseKey[key]
    }

    static func variant(_ key: String) -> (exercise: Exercise, variant: ExerciseVariant)? {
        byVariantKey[key].map { (exercise: $0.0, variant: $0.1) }
    }

    private static func variant(
        _ key: String,
        _ level: Int,
        _ prescription: Prescription,
        _ regions: Set<BodyRegion>,
        equipment: Equipment = .bodyweightOnly,
        support: Bool = false
    ) -> ExerciseVariant {
        ExerciseVariant(
            key: key,
            level: level,
            equipment: equipment,
            prescription: prescription,
            loadedRegions: regions,
            usesSupport: support
        )
    }
}
