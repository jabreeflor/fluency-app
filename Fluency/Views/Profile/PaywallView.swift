import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .annual
    @State private var isPurchasing = false

    enum PremiumPlan: String, CaseIterable {
        case monthly, annual

        var price: String {
            self == .monthly ? "$9.99/mo" : "$49.99/yr"
        }

        var productId: String {
            self == .monthly ? "com.fluency.app.premium.monthly" : "com.fluency.app.premium.annual"
        }

        var perMonth: String {
            self == .monthly ? "$9.99/month" : "$4.17/month"
        }

        var badge: String? {
            self == .annual ? "Best Value" : nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("👑")
                    .font(.system(size: 64))
                Text("Fluency Premium")
                    .font(FluencyTheme.titleFont)
                Text("Unlock everything. Learn faster.")
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "globe", text: "All languages (French, German, Japanese + more)")
                FeatureRow(icon: "heart.fill", text: "Unlimited hearts — never stop a lesson early")
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Unlimited spaced repetition reviews")
                FeatureRow(icon: "chart.bar.fill", text: "Advanced stats and progress insights")
                FeatureRow(icon: "icloud.fill", text: "Multi-device sync")
            }
            .padding(.horizontal, 24)

            Spacer()

            // Plan selector
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(PremiumPlan.allCases, id: \.self) { plan in
                        PlanCard(plan: plan, isSelected: selectedPlan == plan) {
                            selectedPlan = plan
                        }
                    }
                }
                .padding(.horizontal)

                // CTA
                Button {
                    Task { await purchase() }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Start Premium · \(selectedPlan.price)")
                        }
                    }
                }
                .buttonStyle(FluencyButtonStyle())
                .padding(.horizontal)
                .disabled(isPurchasing)

                // Restore
                Button("Restore Purchases") {
                    Task { await restore() }
                }
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)

                Text("Cancel anytime. No commitments.")
                    .font(.caption2)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .padding(.bottom, 8)
            }
            .padding(.bottom, 20)
        }
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Product.products(for: [selectedPlan.productId]).first
            guard let product = result else { return }
            let purchaseResult = try await product.purchase()
            if case .success = purchaseResult {
                dismiss()
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }

    private func restore() async {
        try? await AppStore.sync()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(FluencyTheme.primary)
                .frame(width: 24)
            Text(text)
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textPrimary)
        }
    }
}

struct PlanCard: View {
    let plan: PaywallView.PremiumPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let badge = plan.badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FluencyTheme.gold)
                        .clipShape(Capsule())
                }

                Text(plan.rawValue.capitalized)
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)

                Text(plan.price)
                    .font(FluencyTheme.headlineFont)
                    .foregroundStyle(FluencyTheme.textPrimary)

                Text(plan.perMonth)
                    .font(.caption2)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(isSelected ? FluencyTheme.primary.opacity(0.08) : FluencyTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                    .stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 2)
            )
        }
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
