import Foundation

struct HowTo: Identifiable, Codable, Hashable {
    var id = UUID()
    var title = ""
    var body = ""
}

struct Place: Identifiable, Codable, Hashable {
    var id = UUID()
    var name = ""
    var area = ""
    var note = ""
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text = ""
}

struct Guidebook: Identifiable, Codable, Hashable {
    var id = UUID()
    var name = "My Rental"
    var subtitle = ""
    var town = ""
    var checkIn = "4:00 PM"
    var checkOut = "10:00 AM"
    var doorCode = "Sent 24 hours before arrival"
    var parking = ""
    var wifiNetwork = ""
    var wifiPassword = ""
    var emergency = "Call 911 first. The house address for responders is posted on the fridge. Then call your host."
    var houseCards: [HowTo] = []
    var showDock = true
    var dockCards: [HowTo] = []
    var places: [Place] = []
    var checkout: [ChecklistItem] = []
    var rules: [ChecklistItem] = []
    var hostName = ""
    var hostPhone = ""
    var updated = Date()

    static func starter() -> Guidebook {
        var g = Guidebook()
        g.houseCards = [
            HowTo(title: "Thermostat", body: ""),
            HowTo(title: "Trash & recycling", body: "")
        ]
        g.dockCards = [
            HowTo(title: "Using the boat lift", body: "")
        ]
        g.checkout = [
            "Start the dishwasher with any dirty dishes",
            "Put used towels in the laundry room",
            "Lock the doors"
        ].map { ChecklistItem(text: $0) }
        g.rules = [
            "Quiet hours 10 PM to 8 AM",
            "No smoking inside"
        ].map { ChecklistItem(text: $0) }
        return g
    }
}
