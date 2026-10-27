import OSLog
import StoreKit
import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.subscriptions) private var subscriptions
    @Query private var profiles: [UserProfile]

    @State private var isConfirmingDeletion = false
    @State private var showsDeletionSuccess = false
    @State private var showsDeletionFailure = false
    @State private var deletionCount = 0
    @State private var showsPaywall = false
    @State private var showsManage = false
    @State private var exportFile: ExportFile?
    @State private var showsExportFailure = false
    @State private var showsHealthDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("settings.subscription.status") {
                        Text(subscriptions?.isPro == true ? LocalizedStringKey("settings.subscription.pro") : "settings.subscription.free")
                    }
                    if subscriptions?.isPro != true {
                        Button("settings.subscription.seePlans") { showsPaywall = true }
                            .frame(minHeight: SSLayout.minTouchTarget)
                    }
                    Button("paywall.restore") { Task { await subscriptions?.restore() } }
                        .frame(minHeight: SSLayout.minTouchTarget)
                    Button("paywall.manage") { showsManage = true }
                        .frame(minHeight: SSLayout.minTouchTarget)
                } header: {
                    Text("settings.section.subscription")
                }

                Section {
                    Button {
                        openSystemSettings()
                    } label: {
                        Label("settings.language", systemImage: "globe")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)
                } header: {
                    Text("settings.section.general")
                } footer: {
                    Text("settings.language.footer")
                }

                if let preferences = profiles.first?.preferences {
                    Section {
                        Toggle("settings.voiceGuidance", isOn: binding(preferences, \.voiceGuidanceEnabled))
                            .frame(minHeight: SSLayout.minTouchTarget)
                        Toggle("settings.haptics", isOn: binding(preferences, \.hapticsEnabled))
                            .frame(minHeight: SSLayout.minTouchTarget)
                        if HealthKitService.isAvailable {
                            Toggle("settings.appleHealth", isOn: healthBinding(preferences))
                                .frame(minHeight: SSLayout.minTouchTarget)
                        }
                    } header: {
                        Text("settings.section.workout")
                    } footer: {
                        if HealthKitService.isAvailable {
                            Text("settings.appleHealth.footer")
                        }
                    }
                    .tint(SSColor.accent)
                }

                Section {
                    Label("settings.privacy.localOnly", systemImage: "lock.shield")
                        .foregroundStyle(SSColor.textPrimary)

                    Button {
                        exportData()
                    } label: {
                        Label("settings.export", systemImage: "square.and.arrow.up")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)

                    Button(role: .destructive) {
                        isConfirmingDeletion = true
                    } label: {
                        Label("settings.deleteAll", systemImage: "trash")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)
                } header: {
                    Text("settings.section.privacy")
                }

                Section {
                    Link(destination: AppLinks.privacyPolicy) {
                        Label("settings.privacyPolicy", systemImage: "hand.raised")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)
                    Link(destination: AppLinks.termsOfUse) {
                        Label("settings.termsOfUse", systemImage: "doc.text")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)
                    Link(destination: AppLinks.support) {
                        Label("settings.support", systemImage: "questionmark.circle")
                    }
                    .frame(minHeight: SSLayout.minTouchTarget)
                    LabeledContent("settings.version", value: appVersion)
                    Text("settings.disclaimer")
                        .font(SSFont.footnote)
                        .foregroundStyle(SSColor.textSecondary)
                } header: {
                    Text("settings.section.about")
                }
            }
            .navigationTitle("settings.title")
            .confirmationDialog(
                "settings.deleteAll.confirm.title",
                isPresented: $isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("settings.deleteAll.confirm.action", role: .destructive, action: deleteAllData)
            } message: {
                Text("settings.deleteAll.confirm.message")
            }
            .alert("settings.deleteAll.success", isPresented: $showsDeletionSuccess) {
                Button("common.ok", role: .cancel) {}
            }
            .alert("settings.deleteAll.failure", isPresented: $showsDeletionFailure) {
                Button("common.ok", role: .cancel) {}
            }
            .sensoryFeedback(.success, trigger: deletionCount)
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
                    .environment(\.subscriptions, subscriptions)
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .alert("settings.export.failure", isPresented: $showsExportFailure) {
                Button("common.ok", role: .cancel) {}
            }
            .alert("settings.appleHealth.denied", isPresented: $showsHealthDenied) {
                Button("common.ok", role: .cancel) {}
            }
            .manageSubscriptionsSheet(isPresented: $showsManage)
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    private func binding(_ preferences: UserPreferences, _ keyPath: ReferenceWritableKeyPath<UserPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { newValue in
                preferences[keyPath: keyPath] = newValue
                preferences.updatedAt = .now
                try? modelContext.save()
            }
        )
    }

    private func healthBinding(_ preferences: UserPreferences) -> Binding<Bool> {
        Binding(
            get: { preferences.saveToHealthEnabled },
            set: { enable in
                guard enable else {
                    preferences.saveToHealthEnabled = false
                    try? modelContext.save()
                    return
                }
                guard FeatureAccess.canUseHealthKit(isPro: subscriptions?.isPro ?? false) else {
                    showsPaywall = true
                    return
                }
                Task {
                    if await HealthKitService.shared.requestWorkoutPermission() {
                        preferences.saveToHealthEnabled = true
                        try? modelContext.save()
                    } else {
                        showsHealthDenied = true
                    }
                }
            }
        )
    }

    private func exportData() {
        do {
            exportFile = ExportFile(url: try PersonalDataExporter(context: modelContext).writeFile(now: .now))
        } catch {
            Logger.persistence.error("Export failed: \(String(describing: error))")
            showsExportFailure = true
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func deleteAllData() {
        do {
            try PersonalDataEraser(context: modelContext).eraseAll()
            deletionCount += 1
            showsDeletionSuccess = true
        } catch {
            Logger.persistence.error("Deleting personal data failed: \(String(describing: error))")
            showsDeletionFailure = true
        }
    }
}

#if DEBUG
#Preview {
    SettingsView()
        .modelContainer(PreviewSupport.container(populated: false))
}
#endif

private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// System share sheet for files.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
