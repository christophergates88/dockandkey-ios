import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GuidebookStore
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if store.guidebooks.isEmpty {
                    ContentUnavailableView {
                        Label("No guidebooks yet", systemImage: "book.closed")
                    } description: {
                        Text("Build a guidebook for your rental: Wi-Fi, house how-tos, dock steps, local picks and checkout. Guests open it from a link or a QR sign on the fridge — nothing for them to download.")
                    } actions: {
                        Button("Create your first guidebook") { add() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach($store.guidebooks) { $g in
                            NavigationLink {
                                EditorView(g: $g)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.name).font(.headline)
                                    Text(g.town.isEmpty ? "Tap to edit" : g.town)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { store.guidebooks.remove(atOffsets: $0) }
                    }
                }
            }
            .navigationTitle("Dock & Key")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !pro.isPro {
                        Button("Unlock") { showPaywall = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { add() } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func add() {
        if pro.isPro || store.guidebooks.count < GuidebookStore.freeLimit {
            store.guidebooks.append(Guidebook.starter())
        } else {
            showPaywall = true
        }
    }
}
