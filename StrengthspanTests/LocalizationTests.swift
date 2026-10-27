import Foundation
import Testing
@testable import Strengthspan

/// Reads the compiled string tables from the host app bundle.
@Suite("Localization")
struct LocalizationTests {
    private func table(for localization: String) throws -> [String: String] {
        let url = try #require(
            Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: localization),
            "Missing Localizable.strings for \(localization)"
        )
        return try #require(NSDictionary(contentsOf: url) as? [String: String])
    }

    @Test func englishAndTurkishHaveTheSameKeys() throws {
        let english = try table(for: "en")
        let turkish = try table(for: "tr")
        #expect(!english.isEmpty)
        #expect(Set(english.keys) == Set(turkish.keys))
    }

    /// Keys built at runtime (catalog, options, screening) can't be found by Xcode's extraction.
    @Test func dynamicKeysExistInBothLanguages() throws {
        var keys = ExerciseCatalog.all.flatMap(\.variants).flatMap { [$0.nameKey, $0.instructionKey] }
        keys += ScreeningQuestion.allCases.map(\.textKey)
        keys += AgeRange.allCases.map(\.localizationKey) + ActivityLevel.allCases.map(\.localizationKey)
        keys += ExperienceLevel.allCases.map(\.localizationKey) + PrimaryGoal.allCases.map(\.localizationKey)
        keys += Equipment.allCases.map(\.localizationKey) + BodyRegion.allCases.map(\.localizationKey)
        keys += WorkoutBlock.allCases.map(\.localizationKey)
        keys += Discomfort.allCases.map { "feedback.discomfort.\($0.rawValue)" }
        keys += AssessmentCatalog.all.flatMap { [$0.nameKey, $0.instructionKey, $0.setupKey] }
        keys += (1...3).map { "measurement.level.\($0)" }

        for localization in ["en", "tr"] {
            let table = try table(for: localization)
            for key in keys {
                #expect(table[key] != nil, "\(localization): missing \(key)")
            }
        }
    }

    @Test func noTranslationIsEmptyOrARawKey() throws {
        for localization in ["en", "tr"] {
            for (key, value) in try table(for: localization) {
                #expect(!value.trimmingCharacters(in: .whitespaces).isEmpty, "\(localization): \(key) is empty")
                #expect(value != key, "\(localization): \(key) is untranslated")
            }
        }
    }
}
