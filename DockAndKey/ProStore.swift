import Foundation
import StoreKit

@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.christophergates.dockandkey.pro"

    @Published var isPro = false
    @Published var product: Product?
    @Published var message: String?

    init() {
        Task {
            await refresh()
            await loadProduct()
            await listenForUpdates()
        }
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            // Product not available yet (for example before App Store Connect setup).
        }
    }

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isPro = true
            }
        }
    }

    private func listenForUpdates() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                if transaction.productID == Self.productID {
                    isPro = transaction.revocationDate == nil
                }
                await transaction.finish()
            }
        }
    }

    func buy() async {
        guard let product else {
            message = "The upgrade isn't available yet. Try again once the app is live on the App Store."
            return
        }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                isPro = true
                await transaction.finish()
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
        if !isPro {
            message = "No previous purchase found."
        }
    }
}
