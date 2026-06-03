import SwiftUI
import StoreKit

struct MyPlansView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(SubscriptionManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isAnnual = true

    private var standardProduct: Product? { isAnnual ? store.standardAnnual : store.standardMonthly }
    private var proProduct:      Product? { isAnnual ? store.proAnnual      : store.proMonthly      }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ─────────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Plans")
                                .font(AvaTheme.font(28, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.6)
                            if store.tier.isActive {
                                Text("You're on \(store.tier == .pro ? "Ava Pro" : "Ava") — thanks for subscribing 💛")
                                    .font(AvaTheme.font(13, weight: .medium))
                                    .foregroundStyle(AvaTheme.inkMute)
                            } else {
                                Text("Choose a plan to unlock everything")
                                    .font(AvaTheme.font(13, weight: .medium))
                                    .foregroundStyle(AvaTheme.inkMute)
                            }
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                                .overlay(Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AvaTheme.inkMute))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    // ── Billing toggle ─────────────────────────────────────
                    HStack(spacing: 0) {
                        togglePill(label: "Monthly",           active: !isAnnual) { isAnnual = false }
                        togglePill(label: "Annual — save 37%", active:  isAnnual) { isAnnual = true  }
                    }
                    .background(AvaTheme.bgDeep).clipShape(Capsule())
                    .padding(.horizontal, 28).padding(.bottom, 20)

                    // ── Pro card ───────────────────────────────────────────
                    planCard(
                        isPro: true,
                        name: "Ava Pro",
                        emoji: "⭐",
                        badge: "RECOMMENDED",
                        product: proProduct,
                        features: [
                            "Super Brain Ava — feels more like a real friend",
                            "Remembers more about you & your family",
                            "Weekly Sunday reset — your week summarised",
                            "Morning brief to start your day with clarity",
                            "First to get every new feature",
                        ]
                    )
                    .padding(.horizontal, 18)

                    // ── Standard card ──────────────────────────────────────
                    planCard(
                        isPro: false,
                        name: "Ava",
                        emoji: "✨",
                        badge: nil,
                        product: standardProduct,
                        features: [
                            "Regular Ava — your everyday mental load helper",
                            "Manage your calendar, tasks & grocery list",
                            "Notes for passwords, reminders & important stuff",
                            "Family member profiles",
                        ]
                    )
                    .padding(.horizontal, 18).padding(.top, 12)

                    // ── Footer ─────────────────────────────────────────────
                    HStack(spacing: 20) {
                        footerButton("Restore Purchases") {
                            guard let userId = auth.currentUserId else { return }
                            _Concurrency.Task { await store.restore(userId: userId) }
                        }
                        footerButton("Terms") {
                            openURL(URL(string: "https://avaformoms.com/terms")!)
                        }
                        footerButton("Privacy") {
                            openURL(URL(string: "https://avaformoms.com/privacy")!)
                        }
                    }
                    .padding(.top, 24).padding(.bottom, 10)

                    if let err = store.errorMessage {
                        Text(err)
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(AvaTheme.terracotta)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 8)
                    }

                    Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                        .font(AvaTheme.font(11, weight: .medium))
                        .foregroundStyle(AvaTheme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40).padding(.bottom, 50)
                }
            }
        }
        .task { await store.load() }
    }

    // MARK: - Plan card

    private func planCard(
        isPro: Bool,
        name: String,
        emoji: String,
        badge: String?,
        product: Product?,
        features: [String]
    ) -> some View {
        let isCurrentPlan = (isPro && store.tier == .pro) || (!isPro && store.tier == .standard)

        return VStack(alignment: .leading, spacing: 0) {

            // Name + badge
            HStack {
                HStack(spacing: 8) {
                    Text(emoji).font(.system(size: 18))
                    Text(name)
                        .font(AvaTheme.font(18, weight: .heavy))
                        .foregroundStyle(isPro ? .white : AvaTheme.ink)
                }
                Spacer()
                if isCurrentPlan {
                    Text("CURRENT PLAN")
                        .font(AvaTheme.font(10, weight: .heavy))
                        .foregroundStyle(isPro ? AvaTheme.terracotta : AvaTheme.inkMute)
                        .tracking(0.5).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(isPro ? .white : AvaTheme.bgDeep))
                } else if let badge {
                    Text(badge)
                        .font(AvaTheme.font(10, weight: .heavy))
                        .foregroundStyle(isPro ? AvaTheme.terracotta : AvaTheme.inkMute)
                        .tracking(0.5).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(isPro ? .white : AvaTheme.bgDeep))
                }
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

            // Price — billed amount is always the dominant figure (App Store guideline 3.1.2c)
            VStack(alignment: .leading, spacing: 4) {
                if let product {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(product.displayPrice)
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(isPro ? .white : AvaTheme.ink)
                            .tracking(-0.5)
                        Text(isAnnual ? "/ year" : "/ month")
                            .font(AvaTheme.font(14, weight: .semibold))
                            .foregroundStyle(isPro ? .white.opacity(0.75) : AvaTheme.inkMute)
                    }
                    if isAnnual {
                        Text("\(monthlyEquivalent(product: product)) / month")
                            .font(AvaTheme.font(12, weight: .medium))
                            .foregroundStyle(isPro ? .white.opacity(0.65) : AvaTheme.inkSoft)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isPro ? .white.opacity(0.3) : AvaTheme.bgDeep)
                        .frame(width: 100, height: 28)
                        .overlay(ProgressView().tint(isPro ? .white : AvaTheme.inkSoft).scaleEffect(0.7))
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 18)

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

            // CTA
            Button {
                guard let product, let userId = auth.currentUserId else { return }
                _Concurrency.Task {
                    let success = await store.purchase(product, userId: userId)
                    if success { dismiss() }
                }
            } label: {
                ZStack {
                    Text(isCurrentPlan ? "Current Plan" : (isAnnual ? "Subscribe annually" : "Subscribe to \(name)"))
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
            .buttonStyle(.plain)
            .disabled(product == nil || store.isLoading || isCurrentPlan)
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

    private func monthlyEquivalent(product: Product) -> String {
        product.priceFormatStyle.format(product.price / 12)
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

    private func footerButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AvaTheme.font(12, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute).underline()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MyPlansView()
        .environment(AuthManager())
        .environment(SubscriptionManager())
}
