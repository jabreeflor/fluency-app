import SwiftUI
import StoreKit

// MARK: - Product IDs
// TODO: CONNECT APPLE DEVELOPER — Register these Product IDs in App Store Connect
// under your app's In-App Purchases before going live.
enum FluencyProduct {
    static let monthly = "com.fluency.app.premium.monthly"   // $9.99/month
    static let annual  = "com.fluency.app.premium.annual"    // $59.99/year
}

// MARK: - StoreKit Manager
// TODO: CONNECT APPLE DEVELOPER — Replace placeholder prices with real StoreKit 2
// product fetches once App Store Connect products are configured.
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var purchaseInProgress = false
    @Published var purchaseError: String?

    // Placeholder prices shown until real products load
    let placeholderMonthlyPrice = "$9.99/month"
    let placeholderAnnualPrice  = "$59.99/year"
    let placeholderAnnualMonthly = "$5.00/month" // billed annually

    private init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        do {
            // TODO: CONNECT APPLE DEVELOPER — This will return empty until real products exist in ASC
            products = try await Product.products(for: [FluencyProduct.monthly, FluencyProduct.annual])
        } catch {
            // Expected during development — placeholder UI will show
            products = []
        }
    }

    func monthlyProduct() -> Product? { products.first { $0.id == FluencyProduct.monthly } }
    func annualProduct() -> Product?  { products.first { $0.id == FluencyProduct.annual } }

    func monthlyPriceString() -> String {
        monthlyProduct().map { $0.displayPrice + "/month" } ?? placeholderMonthlyPrice
    }
    func annualPriceString() -> String {
        annualProduct().map { $0.displayPrice + "/year" } ?? placeholderAnnualPrice
    }

    func purchase(_ productId: String) async throws {
        // TODO: CONNECT APPLE DEVELOPER — Real purchase flow below.
        // Uncomment when ASC products are configured and Apple Developer account is linked.
        /*
        guard let product = products.first(where: { $0.id == productId }) else {
            throw StoreError.productNotFound
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
            case .unverified:
                throw StoreError.verificationFailed
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
        */

        // Stub for development: simulate purchase
        purchaseInProgress = true
        try await Task.sleep(nanoseconds: 800_000_000)
        purchaseInProgress = false
    }

    func restorePurchases() async {
        // TODO: CONNECT APPLE DEVELOPER
        // try? await AppStore.sync()
    }
}

enum StoreError: Error {
    case productNotFound
    case verificationFailed
}

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var showingAlert = false
    @State private var alertMessage = ""

    enum PlanType { case monthly, annual }

    private let features: [(icon: String, text: String)] = [
        ("infinity",           "Unlimited lessons, no daily cap"),
        ("waveform",           "Pronunciation coaching & feedback"),
        ("shield.fill",        "Streak Shield — protect your streak"),
        ("bell.badge.fill",    "Smart review reminders"),
        ("arrow.counterclockwise", "Offline mode — learn anywhere"),
    ]

    var body: some View {
        ZStack {
            // Hero gradient background
            FluencyTheme.heroGradientVertical.ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss handle
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 28) {

                        // Hero text
                        VStack(spacing: 10) {
                            Text("Go Pro")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Unlock everything.\nLearn faster.")
                                .font(.system(.title3, design: .default, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Features list
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(features, id: \.text) { feature in
                                HStack(spacing: 14) {
                                    Image(systemName: feature.icon)
                                        .font(.body)
                                        .foregroundStyle(FluencyTheme.gold)
                                        .frame(width: 24)
                                    Text(feature.text)
                                        .font(FluencyTheme.bodyFont)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(FluencyTheme.cardPadding)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))

                        // Plan toggle
                        planToggle

                        // CTA
                        ctaSection

                        // Legal
                        legalFooter
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Plan Toggle

    private var planToggle: some View {
        HStack(spacing: 10) {
            PlanCard(
                title: "Monthly",
                price: store.monthlyPriceString(),
                subtext: "Billed monthly",
                badge: nil,
                isSelected: selectedPlan == .monthly,
                action: { withAnimation(FluencyTheme.springSnappy) { selectedPlan = .monthly } }
            )
            PlanCard(
                title: "Annual",
                price: store.annualPriceString(),
                subtext: store.placeholderAnnualMonthly + "/mo",
                badge: "Save 50%",
                isSelected: selectedPlan == .annual,
                action: { withAnimation(FluencyTheme.springSnappy) { selectedPlan = .annual } }
            )
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchase() }
            } label: {
                HStack(spacing: 8) {
                    if store.purchaseInProgress {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start 7-Day Free Trial")
                            .font(.system(.body, design: .default, weight: .semibold))
                    }
                }
                .foregroundStyle(FluencyTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: FluencyTheme.buttonHeight)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .disabled(store.purchaseInProgress)

            Text("Then \(selectedPlan == .monthly ? store.monthlyPriceString() : store.annualPriceString()). Cancel anytime.")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(.white.opacity(0.75))

            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(FluencyTheme.captionFont)
            .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text("Subscription auto-renews. Cancel in App Store Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            // TODO: CONNECT APPLE DEVELOPER — Link real Terms / Privacy URLs
            HStack(spacing: 16) {
                Button("Terms of Service") {}
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                Button("Privacy Policy") {}
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Purchase

    private func purchase() async {
        let productId = selectedPlan == .monthly ? FluencyProduct.monthly : FluencyProduct.annual
        do {
            try await store.purchase(productId)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let title: String
    let price: String
    let subtext: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(isSelected ? FluencyTheme.primary : .white)
                    Text(price)
                        .font(.system(.headline, design: .default, weight: .bold))
                        .foregroundStyle(isSelected ? FluencyTheme.primary : .white)
                    Text(subtext)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(isSelected ? FluencyTheme.textSecondary : .white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.white : .white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                        .stroke(isSelected ? FluencyTheme.primary : .clear, lineWidth: 2)
                )

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FluencyTheme.gold)
                        .clipShape(Capsule())
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
