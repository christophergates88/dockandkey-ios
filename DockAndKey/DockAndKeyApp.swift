import SwiftUI

@main
struct DockAndKeyApp: App {
    @StateObject private var store = GuidebookStore()
    @StateObject private var pro = ProStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(pro)
                .tint(Color(red: 0.12, green: 0.44, blue: 0.42))
        }
    }
}
