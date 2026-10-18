import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "key.radiowaves.forward")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                    .padding(.top, 12)
                Text("Dock & Key Pro")
                    .font(.title.bold())
                VStack(alignment: .leading, spacing: 10) {
                    Label("Unlimited rentals", systemImage: "checkmark")
                    Label("No Dock & Key line on your guidebooks", systemImage: "checkmark")
                    Label("Paid once, yours for good — no subscription", systemImage: "checkmark")
                }
                .font(.callout)

                if pro.isPro {
                    Label("You have Pro. Thank you!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        Task {
                            await pro.buy()
                            if pro.isPro { dismiss() }
                        }
                    } label: {
                        Text(pro.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Restore purchase") {
                        Task { await pro.restore() }
                    }
                    .font(.callout)
                }

                if let message = pro.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
