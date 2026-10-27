import OSLog
import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var isConfirmingDeletion = false
    @State private var showsDeletionSuccess = false
    @State private var showsDeletionFailure = false
    @State private var deletionCount = 0

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    Label("settings.privacy.localOnly", systemImage: "lock.shield")
                        .foregroundStyle(SSColor.textPrimary)

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
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
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
