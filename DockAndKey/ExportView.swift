import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct ExportView: View {
    let g: Guidebook
    @EnvironmentObject private var pro: ProStore
    @State private var fileURL: URL?
    @State private var link = ""
    @State private var signURL: URL?
    @State private var copiedCode = false

    var body: some View {
        Form {
            Section {
                Text("The guidebook is one self-contained web file. Share it to your computer or wherever you host web pages, then paste its web address below to make the QR sign.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let fileURL {
                    ShareLink(item: fileURL) {
                        Label("Share the guidebook file", systemImage: "doc.richtext")
                    }
                }
                Button {
                    UIPasteboard.general.string = HTMLExporter.html(for: g, pro: pro.isPro)
                    copiedCode = true
                } label: {
                    Label(copiedCode ? "Copied" : "Copy the page's code", systemImage: "doc.on.doc")
                }
            } header: {
                Text("The guidebook page")
            }

            Section {
                TextField("https://… (where the guidebook lives)", text: $link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !link.isEmpty, let qr = Self.qrImage(for: link) {
                    HStack {
                        Spacer()
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                        Spacer()
                    }
                    Button {
                        signURL = renderSign()
                    } label: {
                        Label("Make the fridge sign", systemImage: "qrcode")
                    }
                    if let signURL {
                        ShareLink(item: signURL) {
                            Label("Share the sign (print it)", systemImage: "printer")
                        }
                    }
                }
            } header: {
                Text("QR fridge sign")
            } footer: {
                Text("Print the sign and put it on the fridge. Guests scan it and the guidebook opens in their phone's browser — no app for them.")
            }
        }
        .navigationTitle("Share & QR sign")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            fileURL = HTMLExporter.writeTempFile(for: g, pro: pro.isPro)
        }
        .onChange(of: link) {
            signURL = nil
        }
    }

    static func qrImage(for text: String) -> UIImage? {
        guard !text.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    private func renderSign() -> URL? {
        let renderer = ImageRenderer(content: SignView(g: g, qr: Self.qrImage(for: link)))
        renderer.scale = 3
        guard let ui = renderer.uiImage, let data = ui.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dock-and-key-sign.png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

private struct SignView: View {
    let g: Guidebook
    let qr: UIImage?

    var body: some View {
        VStack(spacing: 14) {
            Text("Welcome to \(g.name)")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
            Text("Scan for your guide to the house")
                .font(.system(size: 16))
            if let qr {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
            }
            if !g.wifiNetwork.isEmpty {
                Text("Wi-Fi: \(g.wifiNetwork)" + (g.wifiPassword.isEmpty ? "" : "  ·  \(g.wifiPassword)"))
                    .font(.system(size: 14, design: .monospaced))
            }
            Text("Dock & Key")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 400)
        .background(Color.white)
        .foregroundStyle(Color(red: 0.07, green: 0.19, blue: 0.18))
    }
}
