import StoreKit
import SwiftUI

/// Strengthspan Pro offer. Prices, periods and trials always come from StoreKit, never from code.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.subscriptions) private var subscriptions

    @State private var selectedID: String?
    @State private var isPurchasing = false
    @State private var message: LocalizedStringKey?
    @State private var showsManage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: SSSpacing.l) {
                        header
                        benefits
                        productList
                        legal
                    }
                    .padding(SSSpacing.l)
                }
                actions
            }
            .background(SSColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                        .accessibilityIdentifier("paywall.close")
                }
            }
            .task { await subscriptions?.load() }
            .onChange(of: subscriptions?.isPro ?? false) { _, isPro in
                if isPro { dismiss() }
            }
            .manageSubscriptionsSheet(isPresented: $showsManage)
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Text("paywall.title")
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("paywall.subtitle")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: SSSpacing.m) {
            benefit("paywall.benefit.plan", systemImage: "calendar")
            benefit("paywall.benefit.adapt", systemImage: "arrow.up.right")
            benefit("paywall.benefit.reassess", systemImage: "ruler")
            benefit("paywall.benefit.progress", systemImage: "chart.line.uptrend.xyaxis")
            benefit("paywall.benefit.health", systemImage: "heart")
        }
        .padding(SSSpacing.l)
        .ssCardBackground()
    }

    private func benefit(_ text: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            Text(text)
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(SSColor.accent)
        }
    }

    @ViewBuilder
    private var productList: some View {
        if let subscriptions {
            if subscriptions.isLoading && subscriptions.products.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if subscriptions.products.isEmpty {
                VStack(alignment: .leading, spacing: SSSpacing.s) {
                    SSEmptyState("paywall.unavailable", systemImage: "wifi.exclamationmark")
                    Button("paywall.retry") { Task { await subscriptions.load() } }
                        .buttonStyle(.ssSecondary)
                }
            } else {
                ForEach(subscriptions.products, id: \.id) { product in
                    productRow(product, store: subscriptions)
                }
            }
        }
    }

    private func productRow(_ product: Product, store: SubscriptionStore) -> some View {
        let isSelected = (selectedID ?? store.products.first?.id) == product.id
        return Button {
            selectedID = product.id
        } label: {
            VStack(alignment: .leading, spacing: SSSpacing.xs) {
                HStack {
                    Text(product.displayName)
                        .font(SSFont.headline)
                    Spacer()
                    Text(priceText(product))
                        .font(SSFont.headline.monospacedDigit())
                }
                if store.isEligibleForTrial(product), let offer = product.subscription?.introductoryOffer {
                    Text("paywall.trial \(offer.period.localizedDuration)")
                        .font(SSFont.callout)
                        .foregroundStyle(SSColor.accent)
                }
                if product.id == SubscriptionProduct.annualPro.rawValue, let monthly = monthlyEquivalent(product) {
                    Text("paywall.monthlyEquivalent \(monthly)")
                        .font(SSFont.footnote)
                        .foregroundStyle(SSColor.textSecondary)
                }
            }
            .foregroundStyle(SSColor.textPrimary)
            .padding(SSSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SSColor.accentSoft : SSColor.surface, in: RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? SSColor.accent : SSColor.separator, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Text("paywall.renewalTerms")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
            HStack(spacing: SSSpacing.l) {
                Link("settings.privacyPolicy", destination: AppLinks.privacyPolicy)
                Link("settings.termsOfUse", destination: AppLinks.termsOfUse)
            }
            .font(SSFont.footnote)
            .tint(SSColor.accent)
        }
    }

    private var actions: some View {
        VStack(spacing: SSSpacing.s) {
            if let message {
                Text(message)
                    .font(SSFont.callout)
                    .foregroundStyle(SSColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let product = selectedProduct, let store = subscriptions {
                Button {
                    Task { await buy(product, store: store) }
                } label: {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text(store.isEligibleForTrial(product) ? LocalizedStringKey("paywall.startTrial") : "paywall.subscribe")
                    }
                }
                .buttonStyle(.ssPrimary)
                .disabled(isPurchasing)
            }
            HStack(spacing: SSSpacing.s) {
                Button("paywall.restore") {
                    Task {
                        await subscriptions?.restore()
                        if subscriptions?.isPro != true { message = "paywall.nothingToRestore" }
                    }
                }
                .buttonStyle(.ssSecondary)
                Button("paywall.manage") { showsManage = true }
                    .buttonStyle(.ssSecondary)
            }
        }
        .padding(SSSpacing.l)
        .background(SSColor.background)
    }

    // MARK: Helpers

    private var selectedProduct: Product? {
        guard let products = subscriptions?.products else { return nil }
        return products.first { $0.id == selectedID } ?? products.first
    }

    private func priceText(_ product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.displayPrice }
        return String(localized: "paywall.pricePer \(product.displayPrice) \(period.localizedDuration)")
    }

    private func monthlyEquivalent(_ product: Product) -> String? {
        guard product.subscription?.subscriptionPeriod.unit == .year else { return nil }
        let perMonth = product.price / 12
        return perMonth.formatted(product.priceFormatStyle)
    }

    private func buy(_ product: Product, store: SubscriptionStore) async {
        isPurchasing = true
        defer { isPurchasing = false }
        switch await store.purchase(product) {
        case .purchased: message = nil
        case .pending: message = "paywall.pending"
        case .cancelled: message = nil
        case .failed: message = "paywall.failed"
        }
    }
}
