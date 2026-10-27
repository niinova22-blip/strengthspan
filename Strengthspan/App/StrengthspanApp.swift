import SwiftData
import SwiftUI

@main
struct StrengthspanApp: App {
    private let bootstrap = AppBootstrap.make()
    @State private var subscriptions = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .ready(let container):
                RootView()
                    .modelContainer(container)
                    .environment(\.subscriptions, subscriptions)
                    .task { await subscriptions.load() }
            case .failed:
                StartupErrorView()
            }
        }
    }
}
