import Foundation
import OSLog

/// Log categories. Never log personal health or measurement values; interpolated values
/// are private by default in `Logger` and must stay that way for user data.
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.strengthspan.app"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
