import SwiftUI

struct PaywallView: View {
    var data: OnboardingData
    let onComplete: () -> Void

    @State private var isAnnual = true
    @State private var selectedPlan: Plan = .pro

    enum Plan { case standard, pro }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                VStack(spacing: 10) {
                    Text("Ava's ready for you\(data.name.isEmpty ? "" : ", \(data.name)").")
                        .font(AvaTheme.font(30, weight: .heavy))
                        .foregroundStyle(AvaTheme.ink)
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)

                    // Personalised summary chips
                    HStack(spacing: 6) {
                        summaryChip(data.familySummary)
                        if data.hasSchoolPickup { summaryChip("school run") }
                        summaryChip(data.loadSummary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 28)

                // ── Billing toggle ────────────────────────────────────────
                HStack(spacing: 0) {
                    togglePill(label: "Monthly", active: !isAnnual) { isAnnual = false }
                    togglePill(label: "Annual — save 37%", active: isAnnual) { isAnnual = true }
                }
                .background(AvaTheme.bgDeep)
                .clipShape(Capsule())
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                // ── Pro plan card (recommended) ───────────────────────────
                planCard(
                    plan: .pro,
                    badge: "RECOMMENDED",
                    name: "Ava Pro",
                    emoji: "⭐",
                    price: isAnnual ? "$18.75/mo" : "$29.99/mo",
                    billingNote: isAnnual ? "billed $224.99/year" : "billed monthly",
                    trialNote: isAnnual ? "7-day free trial" : nil,
                    features: [
                        "Sonnet AI — deeper, warmer responses",
                        "Expanded memory — remembers more, further back",
                        "Weekly life summary every Sunday",
                        "Richer morning brief",
                        "Early access to new features",
                    ],
                    ctaLabel: isAnnual ? "Start 7-day free trial" : "Subscribe to Ava Pro"
                )
                .padding(.horizontal, 18)

                // ── Standard plan card ────────────────────────────────────
                planCard(
                    plan: .standard,
                    badge: nil,
                    name: "Ava",
                    emoji: "✨",
                    price: isAnnual ? "$6.25/mo" : "$9.99/mo",
                    billingNote: isAnnual ? "billed $74.99/year" : "billed monthly",
                    trialNote: nil,
                    features: [
                        "Smart AI routing (Haiku + Sonnet)",
                        "Full calendar, tasks & grocery",
                        "Daily brief & reminders",
                        "Family member profiles",
                    ],
                    ctaLabel: isAnnual ? "Start with Ava" : "Start with Ava"
                )
                .padding(.horizontal, 18)
                .padding(.top, 12)

                // ── Footer links ──────────────────────────────────────────
                HStack(spacing: 20) {
                    footerLink("Restore purchases")
                    footerLink("Terms")
                    footerLink("Privacy")
                }
                .padding(.top, 24)
                .padding(.bottom, 50)

                Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                    .font(AvaTheme.font(11, weight: .medium))
                    .foregroundStyle(AvaTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .background(AvaTheme.bg.ignoresSafeArea())
    }

    // MARK: - Plan card

    private func planCard(
        plan: Plan,
        badge: String?,
        name: String,
        emoji: String,
        price: String,
        billingNote: String,
        trialNote: String?,
        features: [String],
        ctaLabel: String
    ) -> some View {
        let isPro = plan == .pro
        return VStack(alignment: .leading, spacing: 0) {

            // Top bar
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
                        .tracking(0.5)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(isPro ? .white : AvaTheme.bgDeep)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Price
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(price)
                    .font(AvaTheme.font(28, weight: .heavy))
                    .foregroundStyle(isPro ? .white : AvaTheme.ink)
                    .tracking(-0.5)
                VStack(alignment: .leading, spacing: 2) {
                    Text(billingNote)
                        .font(AvaTheme.font(12, weight: .medium))
                        .foregroundStyle(isPro ? .white.opacity(0.75) : AvaTheme.inkMute)
                    if let trial = trialNote {
                        Text(trial)
                            .font(AvaTheme.font(12, weight: .heavy))
                            .foregroundStyle(isPro ? .white : AvaTheme.terracotta)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

            // Divider
            Rectangle()
                .fill(isPro ? .white.opacity(0.2) : AvaTheme.line)
                .frame(height: 0.5)
                .padding(.horizontal, 20)

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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // CTA button
            Button(action: onComplete) {
                // TODO: Replace onComplete with RevenueCat purchase call
                // RevenueCat: Purchases.shared.purchase(package: selectedPackage) { ... }
                Text(ctaLabel)
                    .font(AvaTheme.font(15, weight: .heavy))
                    .foregroundStyle(isPro ? AvaTheme.terracottaDeep : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        if isPro { Capsule().fill(.white) }
                        else     { Capsule().fill(AvaTheme.blushTerracotta) }
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .background {
            if isPro { AvaTheme.blushTerracotta }
            else     { AvaTheme.cream }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(isPro ? AvaTheme.terracotta : Color.clear, lineWidth: 2)
        )
        .shadow(
            color: isPro ? AvaTheme.terracotta.opacity(0.3) : AvaTheme.ink.opacity(0.06),
            radius: isPro ? 20 : 8, x: 0, y: isPro ? 10 : 4
        )
    }

    // MARK: - Helpers

    private func togglePill(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AvaTheme.font(13, weight: .bold))
                .foregroundStyle(active ? .white : AvaTheme.inkMute)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(
                    Capsule().fill(active ? AvaTheme.terracotta : Color.clear)
                )
                .animation(.spring(duration: 0.25), value: active)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(AvaTheme.font(12, weight: .bold))
            .foregroundStyle(AvaTheme.inkMute)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(AvaTheme.cream))
    }

    private func footerLink(_ label: String) -> some View {
        Button(action: {
            // TODO: Open URL for terms/privacy, call RevenueCat restore for "Restore purchases"
        }) {
            Text(label)
                .font(AvaTheme.font(12, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute)
                .underline()
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    let d = OnboardingData()
    d.name = "Claire"; d.hasPartner = true
    d.kids = [.init(), .init()]
    d.hasSchoolPickup = true
    d.mentalLoadAreas = [.meals, .school, .tasks]
    return PaywallView(data: d, onComplete: {})
}
