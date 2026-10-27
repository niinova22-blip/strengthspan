import SwiftUI

/// App-wide dependencies exposed through the SwiftUI environment.
/// Previews and tests override these with `.environment(\.appClock, FixedClock(now: ...))`.
extension EnvironmentValues {
    @Entry var appClock: any AppClock = SystemClock()
    @Entry var reassessmentPolicy: ReassessmentPolicy = .standard
}
