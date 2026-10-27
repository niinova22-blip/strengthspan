import SwiftData
import SwiftUI

@main
struct StrengthspanApp: App {
    private let bootstrap = AppBootstrap.make()

    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .ready(let container):
                RootView()
                    .modelContainer(container)
            case .failed:
                StartupErrorView()
            }
        }
    }
}
