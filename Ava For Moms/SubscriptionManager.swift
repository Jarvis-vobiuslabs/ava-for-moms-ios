import StoreKit
import Supabase

// ── File-level task helpers (avoids @Observable + Task{} Swift 6 conflict) ─

private func makeTransactionListenerTask(
    onUpdate: @MainActor @escaping (SubscriptionManager.Tier) async -> Void
) -> _Concurrency.Task<Void, Never> {
    _Concurrency.Task {
        for await result in Transaction.updates {
            if case .verified(let tx) = result {
                await tx.finish()
                let tier = SubscriptionManager.tier(for: tx.productID)
                await onUpdate(tier)
            }
        }
    }
}

// ── SubscriptionManager ───────────────────────────────────────────────────

@Observable
final class SubscriptionManager {

    // MARK: - Types

    enum Tier: String {
        case none, standard, pro
        var isActive: Bool { self != .none }
        var isPro:    Bool { self == .pro }
    }

    static let productIDs = [
        "com.avaformoms.ava.standard.monthly",
        "com.avaformoms.ava.standard.annual",
        "com.avaformoms.ava.pro.monthly",
        "com.avaformoms.ava.pro.annual",
    ]

    static func tier(for productID: String) -> Tier {
        if productID.contains(".pro.")      { return .pro }
        if productID.contains(".standard.") { return .standard }
        return .none
    }

    // MARK: - State

    var tier: Tier = .none
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private var listenerTask: _Concurrency.Task<Void, Never>?

    // Convenience accessors
    var standardMonthly: Product? { products.first { $0.id.contains("standard.monthly") } }
    var standardAnnual:  Product? { products.first { $0.id.contains("standard.annual")  } }
    var proMonthly:      Product? { products.first { $0.id.contains("pro.monthly")       } }
    var proAnnual:       Product? { products.first { $0.id.contains("pro.annual")        } }

    init() {
        listenerTask = makeTransactionListenerTask { [weak self] newTier in
            self?.tier = newTier
        }
    }

    deinit { listenerTask?.cancel() }

    // MARK: - Load products + check entitlements

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch products from App Store
        if let fetched = try? await Product.products(for: Self.productIDs) {
            products = fetched.sorted { $0.price < $1.price }
        }

        // Check what the user already owns
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var highest: Tier = .none
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.revocationDate == nil {
                let t = Self.tier(for: tx.productID)
                if t == .pro { highest = .pro; break }
                if t == .standard { highest = .standard }
            }
        }
        tier = highest
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product, userId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    errorMessage = "Purchase could not be verified."
                    return false
                }
                await tx.finish()
                let newTier = Self.tier(for: tx.productID)
                tier = newTier
                // Sync to Supabase so edge functions can check subscription tier
                await syncToSupabase(userId: userId, productID: tx.productID, tier: newTier)
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval (Ask to Buy)."
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = friendlyPurchaseError(error)
            return false
        }
    }

    // MARK: - Restore

    func restore(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if tier != .none {
                await syncToSupabase(userId: userId, productID: nil, tier: tier)
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }

    // MARK: - Sync to Supabase

    private func syncToSupabase(userId: UUID, productID: String?, tier: Tier) async {
        let isAnnual = productID?.contains("annual") ?? false
        let row: [String: AnyJSON] = [
            "user_id":  .string(userId.uuidString),
            "tier":     .string(tier.rawValue),
            "status":   .string(tier.isActive ? "active" : "inactive"),
            "is_annual": .bool(isAnnual),
        ]
        _ = try? await (try? supabase
            .from("subscriptions")
            .upsert(row, onConflict: "user_id", ignoreDuplicates: false)
        )?.execute()
    }

    // MARK: - Error helper

    private func friendlyPurchaseError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("network") || msg.contains("internet") {
            return "No internet connection. Please try again."
        }
        if msg.contains("cancelled") { return nil ?? "" }
        return "Purchase failed. Please try again."
    }
}
