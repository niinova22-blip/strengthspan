import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.first?.onboardingCompletedAt == nil {
            OnboardingView()
        } else {
            tabs
        }
    }

    private var tabs: some View {
        TabView {
            TodayView()
                .tabItem { Label("tab.today", systemImage: "sun.max") }

            ProgressDashboardView()
                .tabItem { Label("tab.progress", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
        }
        .tint(SSColor.accent)
    }
}

#if DEBUG
#Preview {
    RootView()
        .modelContainer(PreviewSupport.container(populated: true))
}
#endif
