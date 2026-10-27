import Foundation
import Testing

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

    @Test func noTranslationIsEmptyOrARawKey() throws {
        for localization in ["en", "tr"] {
            for (key, value) in try table(for: localization) {
                #expect(!value.trimmingCharacters(in: .whitespaces).isEmpty, "\(localization): \(key) is empty")
                #expect(value != key, "\(localization): \(key) is untranslated")
            }
        }
    }
}
