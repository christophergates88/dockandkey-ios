import Foundation

@MainActor
final class GuidebookStore: ObservableObject {
    static let freeLimit = 1

    @Published var guidebooks: [Guidebook] = [] {
        didSet { save() }
    }

    private var loaded = false

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("guidebooks.json")
    }

    init() {
        load()
    }

    func load() {
        defer { loaded = true }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Guidebook].self, from: data) {
            guidebooks = decoded
        }
    }

    func save() {
        guard loaded else { return }
        if let data = try? JSONEncoder().encode(guidebooks) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
