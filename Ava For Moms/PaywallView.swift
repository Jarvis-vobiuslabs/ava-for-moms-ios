import SwiftUI
import StoreKit

struct PaywallView: View {
    var data: OnboardingData
    let onComplete: () -> Void
    var onSkip: (() -> Void)? = nil

    @Environment(AuthManager.self) private var auth
    @Environment(SubscriptionManager.self) private var store
    @State private var isAnnual = true
    @State private var showTerms = false
    @State private var showPrivacy = false

    // Real products from StoreKit (shows local currency + correct prices)
    private var standardProduct: Product? { isAnnual ? store.standardAnnual : store.standardMonthly }
    private var proProduct:      Product? { isAnnual ? store.proAnnual      : store.proMonthly      }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────────
                VStack(spacing: 10) {
                    Text("Ava's ready for you\(data.name.isEmpty ? "" : ", \(data.name)").")
                        .font(AvaTheme.font(30, weight: .heavy))
                        .foregroundStyle(AvaTheme.ink).tracking(-0.8)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        summaryChip(data.familySummary)
                        if data.hasSchoolPickup { summaryChip("school run") }
                        summaryChip(data.loadSummary)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 60).padding(.bottom, 28)

                // ── Skip option ────────────────────────────────────────────
                if let onSkip {
                    Button(action: onSkip) {
                        Text("Just check it out — try 1 free chat first →")
                            .font(AvaTheme.font(13, weight: .semibold))
                            .foregroundStyle(AvaTheme.terracotta)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }

                // ── Billing toggle ─────────────────────────────────────────
                HStack(spacing: 0) {
                    togglePill(label: "Monthly",        active: !isAnnual) { isAnnual = false }
                    togglePill(label: "Annual — save 37%", active: isAnnual)  { isAnnual = true  }
                }
                .background(AvaTheme.bgDeep).clipShape(Capsule())
                .padding(.horizontal, 28).padding(.bottom, 20)

                // ── Pro card ───────────────────────────────────────────────
                planCard(
                    isPro: true,
                    name: "Ava Pro",
                    emoji: "⭐",
                    badge: "RECOMMENDED",
                    product: proProduct,
                    annualSubtitle: nil,
                    features: [
                        "Super Brain Ava — feels more like a real friend",
                        "Remembers more about you & your family",
                        "Weekly Sunday reset — your week summarised",
                        "Morning brief to start your day with clarity",
                        "First to get every new feature",
                    ]
                )
                .padding(.horizontal, 18)

                // ── Standard card ──────────────────────────────────────────
                planCard(
                    isPro: false,
                    name: "Ava",
                    emoji: "✨",
                    badge: nil,
                    product: standardProduct,
                    annualSubtitle: nil,
                    features: [
                        "Regular Ava — your everyday mental load helper",
                        "Manage your calendar, tasks & grocery list",
                        "Notes for passwords, reminders & important stuff",
                        "Family member profiles",
                    ]
                )
                .padding(.horizontal, 18).padding(.top, 12)

                // ── Footer ─────────────────────────────────────────────────
                HStack(spacing: 20) {
                    footerLink("Restore purchases")
                    footerLink("Terms")
                    footerLink("Privacy")
                }
                .padding(.top, 24).padding(.bottom, 12)

                Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                    .font(AvaTheme.font(11, weight: .medium))
                    .foregroundStyle(AvaTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40).padding(.bottom, 40)
            }
        }
        .background(AvaTheme.bg.ignoresSafeArea())
        .sheet(isPresented: $showTerms)   { LegalView(type: .terms) }
        .sheet(isPresented: $showPrivacy) { LegalView(type: .privacy) }
        .task { await store.load() }
    }

    // MARK: - Plan card

    private func planCard(
        isPro: Bool,
        name: String,
        emoji: String,
        badge: String?,
        product: Product?,
        annualSubtitle: String?,
        features: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Name + badge
            HStack {
                HStack(spacing: 8) {
                    Text(emoji).font(.system(size: 18))
                    Text(name)
                        .font(AvaTheme.font(18, weight: .heavy))
                        .foregroundStyle(isPro ? .white : AvaTheme.ink)
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(AvaTheme.font(10, weight: .heavy))
                        .foregroundStyle(isPro ? AvaTheme.terracotta : AvaTheme.inkMute)
                        .tracking(0.5).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(isPro ? .white : AvaTheme.bgDeep))
                }
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

            // Price — real from StoreKit or loading placeholder
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let product {
                    Text(isAnnual
                         ? monthlyEquivalent(product: product)
                         : product.displayPrice)
                        .font(AvaTheme.font(28, weight: .heavy))
                        .foregroundStyle(isPro ? .white : AvaTheme.ink)
                        .tracking(-0.5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAnnual ? "per month, billed \(product.displayPrice)/yr" : "per month")
                            .font(AvaTheme.font(12, weight: .medium))
                            .foregroundStyle(isPro ? .white.opacity(0.75) : AvaTheme.inkMute)
                        if let sub = annualSubtitle {
                            Text(sub)
                                .font(AvaTheme.font(12, weight: .heavy))
                                .foregroundStyle(isPro ? .white : AvaTheme.terracotta)
                        }
                    }
                } else {
                    // Loading state
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(isPro ? 0.3 : 0.0))
                        .fill(isPro ? .white.opacity(0.3) : AvaTheme.bgDeep)
                        .frame(width: 100, height: 28)
                        .overlay(ProgressView().tint(isPro ? .white : AvaTheme.inkSoft).scaleEffect(0.7))
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 18)

            // Divider
            Rectangle()
                .fill(isPro ? .white.opacity(0.2) : AvaTheme.line)
                .frame(height: 0.5).padding(.horizontal, 20)

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(isPro ? .white.opacity(0.9) : AvaTheme.sage)
                        Text(feature)
                            .font(AvaTheme.font(14, weight: .medium))
                            .foregroundStyle(isPro ? .white.opacity(0.9) : AvaTheme.ink)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 16)

            // CTA button
            Button {
                guard let product, let userId = auth.currentUserId else { return }
                _Concurrency.Task {
                    let success = await store.purchase(product, userId: userId)
                    if success { onComplete() }
                }
            } label: {
                ZStack {
                    Text(isAnnual ? "Subscribe annually" : "Subscribe to \(name)")
                        .font(AvaTheme.font(15, weight: .heavy))
                        .foregroundStyle(isPro ? AvaTheme.terracottaDeep : .white)
                        .opacity(store.isLoading ? 0 : 1)
                    if store.isLoading { ProgressView().tint(isPro ? AvaTheme.terracottaDeep : .white) }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background {
                    if isPro { Capsule().fill(.white) }
                    else     { Capsule().fill(AvaTheme.blushTerracotta) }
                }
            }
            .buttonStyle(.plain).disabled(product == nil || store.isLoading)
            .padding(.horizontal, 16).padding(.bottom, 18)
        }
        .background {
            if isPro { AvaTheme.blushTerracotta }
            else     { AvaTheme.cream }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(isPro ? AvaTheme.terracotta : Color.clear, lineWidth: 2))
        .shadow(color: isPro ? AvaTheme.terracotta.opacity(0.3) : AvaTheme.ink.opacity(0.06),
                radius: isPro ? 20 : 8, x: 0, y: isPro ? 10 : 4)
    }

    // MARK: - Helpers

    // Divide annual price by 12 for "per month" display
    private func monthlyEquivalent(product: Product) -> String {
        let monthly = product.price / 12
        let formatted = product.priceFormatStyle.format(monthly)
        return formatted
    }

    private func togglePill(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AvaTheme.font(13, weight: .bold))
                .foregroundStyle(active ? .white : AvaTheme.inkMute)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(active ? AvaTheme.terracotta : Color.clear))
                .animation(.spring(duration: 0.25), value: active)
        }
        .buttonStyle(.plain).frame(maxWidth: .infinity)
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(AvaTheme.font(12, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(AvaTheme.cream))
    }

    private func footerLink(_ label: String) -> some View {
        Button {
            if label == "Terms"            { showTerms   = true }
            if label == "Privacy"          { showPrivacy = true }
            if label == "Restore purchases" {
                guard let userId = auth.currentUserId else { return }
                _Concurrency.Task { await store.restore(userId: userId) }
            }
        } label: {
            Text(label)
                .font(AvaTheme.font(12, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute).underline()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let d = OnboardingData(); d.name = "Claire"
    d.kids = [.init(), .init()]; d.hasSchoolPickup = true
    d.mentalLoadAreas = [.meals, .school]
    return PaywallView(data: d, onComplete: {})
        .environment(AuthManager()).environment(SubscriptionManager())
}
