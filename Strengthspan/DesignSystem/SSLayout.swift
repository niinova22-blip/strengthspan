import CoreGraphics

enum SSSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum SSRadius {
    static let card: CGFloat = 20
    static let button: CGFloat = 14
}

enum SSLayout {
    /// Larger than Apple's 44 pt minimum, for comfortable use by people 45+.
    static let minTouchTarget: CGFloat = 52
}
