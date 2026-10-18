import SwiftUI
import UIKit

struct GuestView: View {
    let g: Guidebook
    @State private var tab = 0
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $tab) {
                Text("Arrival").tag(0)
                Text("House").tag(1)
                if g.showDock { Text("Dock").tag(2) }
                Text("Eat").tag(3)
                Text("Leaving").tag(4)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if tab == 0 && !g.subtitle.isEmpty {
                        Text(g.subtitle).foregroundStyle(.secondary)
                    }
                    switch tab {
                    case 0:
                        arrival
                    case 1:
                        howTos(g.houseCards)
                        if !g.rules.isEmpty { rulesBox }
                    case 2:
                        howTos(g.dockCards)
                    case 3:
                        eat
                    default:
                        leaving
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .navigationTitle(g.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var arrival: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox("Arrival") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Check-in", value: g.checkIn)
                    LabeledContent("Checkout", value: g.checkOut)
                    if !g.doorCode.isEmpty { LabeledContent("Door code", value: g.doorCode) }
                    if !g.parking.isEmpty { Text(g.parking).font(.callout) }
                }
            }
            if !g.wifiNetwork.isEmpty || !g.wifiPassword.isEmpty {
                GroupBox("Wi-Fi") {
                    VStack(alignment: .leading, spacing: 8) {
                        if !g.wifiNetwork.isEmpty { LabeledContent("Network", value: g.wifiNetwork) }
                        if !g.wifiPassword.isEmpty {
                            LabeledContent("Password", value: g.wifiPassword)
                            Button(copied ? "Copied" : "Copy password") {
                                UIPasteboard.general.string = g.wifiPassword
                                copied = true
                            }
                            .font(.callout)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !g.emergency.isEmpty {
                GroupBox("In an emergency") {
                    Text(g.emergency)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func howTos(_ cards: [HowTo]) -> some View {
        ForEach(cards) { c in
            GroupBox(c.title.isEmpty ? "How-to" : c.title) {
                Text(c.body)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var rulesBox: some View {
        GroupBox("House rules") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(g.rules) { r in
                    if !r.text.isEmpty { Text("• " + r.text).font(.callout) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var eat: some View {
        ForEach(g.places) { p in
            GroupBox(p.name.isEmpty ? "Place" : p.name) {
                VStack(alignment: .leading, spacing: 4) {
                    if !p.area.isEmpty {
                        Text(p.area).font(.footnote).foregroundStyle(.secondary)
                    }
                    if !p.note.isEmpty {
                        Text(p.note).font(.callout)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var leaving: some View {
        GroupBox("Checkout by \(g.checkOut)") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(g.checkout.enumerated()), id: \.element.id) { index, step in
                    if !step.text.isEmpty {
                        Text("\(index + 1). " + step.text).font(.callout)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
