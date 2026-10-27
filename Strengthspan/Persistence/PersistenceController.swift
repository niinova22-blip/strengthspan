import SwiftData

enum PersistenceController {
    /// Creates the app's model container. The store stays on device: CloudKit is explicitly off.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: StrengthspanMigrationPlan.self,
            configurations: configuration
        )
    }
}
