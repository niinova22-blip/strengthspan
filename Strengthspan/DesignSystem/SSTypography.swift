import SwiftUI

/// Type tokens built only on system text styles so Dynamic Type scales every size.
enum SSFont {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    /// Counters and scores: rounded, with fixed-width digits so values don't jitter.
    static let metric = Font.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit()
}
