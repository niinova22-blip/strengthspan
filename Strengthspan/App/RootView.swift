import SwiftUI

struct RootView: View {
    var body: some View {
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
