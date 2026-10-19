import SwiftUI

struct EditorView: View {
    @Binding var g: Guidebook

    var body: some View {
        Form {
            Section("The rental") {
                TextField("Rental name (Heron House)", text: $g.name)
                TextField("One-line welcome for guests", text: $g.subtitle, axis: .vertical)
                TextField("Town or lake", text: $g.town)
            }

            Section("Arrival") {
                TextField("Check-in time", text: $g.checkIn)
                TextField("Checkout time", text: $g.checkOut)
                TextField("Door code note", text: $g.doorCode)
                TextField("Parking", text: $g.parking, axis: .vertical)
            }

            Section("Wi-Fi") {
                TextField("Network name", text: $g.wifiNetwork)
                TextField("Password", text: $g.wifiPassword)
            }

            Section("House how-tos") {
                ForEach($g.houseCards) { $c in
                    NavigationLink(c.title.isEmpty ? "New how-to" : c.title) {
                        HowToEditor(c: $c)
                    }
                }
                .onDelete { g.houseCards.remove(atOffsets: $0) }
                Button("Add a how-to") { g.houseCards.append(HowTo()) }
            }

            Section("Dock & lake") {
                Toggle("This rental has a dock", isOn: $g.showDock)
                if g.showDock {
                    ForEach($g.dockCards) { $c in
                        NavigationLink(c.title.isEmpty ? "New how-to" : c.title) {
                            HowToEditor(c: $c)
                        }
                    }
                    .onDelete { g.dockCards.remove(atOffsets: $0) }
                    Button("Add a dock how-to") { g.dockCards.append(HowTo()) }
                }
            }

            Section("Eat & drink") {
                ForEach($g.places) { $p in
                    NavigationLink(p.name.isEmpty ? "New place" : p.name) {
                        PlaceEditor(p: $p)
                    }
                }
                .onDelete { g.places.remove(atOffsets: $0) }
                Button("Add a place") { g.places.append(Place()) }
            }

            Section("Checkout steps") {
                ForEach($g.checkout) { $item in
                    TextField("Step", text: $item.text)
                }
                .onDelete { g.checkout.remove(atOffsets: $0) }
                Button("Add a step") { g.checkout.append(ChecklistItem()) }
            }

            Section("House rules") {
                ForEach($g.rules) { $item in
                    TextField("Rule", text: $item.text)
                }
                .onDelete { g.rules.remove(atOffsets: $0) }
                Button("Add a rule") { g.rules.append(ChecklistItem()) }
            }

            Section("Host & emergencies") {
                TextField("Host name", text: $g.hostName)
                TextField("Host phone", text: $g.hostPhone)
                TextField("Emergency note", text: $g.emergency, axis: .vertical)
            }

            Section {
                NavigationLink {
                    GuestView(g: g)
                } label: {
                    Label("Preview as a guest", systemImage: "eye")
                }
                NavigationLink {
                    ExportView(g: g)
                } label: {
                    Label("Send to renter & QR sign", systemImage: "paperplane.fill")
                }
            }
        }
        .navigationTitle(g.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HowToEditor: View {
    @Binding var c: HowTo

    var body: some View {
        Form {
            TextField("Title (Hot tub, Boat lift…)", text: $c.title)
            Section("Steps or notes, in plain words") {
                TextEditor(text: $c.body)
                    .frame(minHeight: 160)
            }
        }
        .navigationTitle(c.title.isEmpty ? "How-to" : c.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaceEditor: View {
    @Binding var p: Place

    var body: some View {
        Form {
            TextField("Name", text: $p.name)
            TextField("Where (Greensboro · on the water)", text: $p.area)
            TextField("Why guests will like it", text: $p.note, axis: .vertical)
        }
        .navigationTitle(p.name.isEmpty ? "Place" : p.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
