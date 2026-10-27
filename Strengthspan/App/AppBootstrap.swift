import Foundation
import OSLog
import SwiftData

/// Result of preparing the app's dependencies at launch.
///
/// A failure to open the store is surfaced as a recoverable screen instead of a crash,
/// so the user is never left with an app that silently closes.
enum AppBootstrap {
    case ready(ModelContainer)
    case failed

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppBootstrap {
        let inMemory = arguments.contains(LaunchArgument.uiTesting)
        do {
            return .ready(try PersistenceController.makeContainer(inMemory: inMemory))
        } catch {
            Logger.persistence.fault("Failed to open model container: \(String(describing: error))")
            return .failed
        }
    }
}
