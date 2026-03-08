/*

Copyright 2020 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  QRCodeView.swift
//  DailyToolbox
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - QR Type

private enum QRType: String, CaseIterable, Identifiable {
    case url     = "URL"
    case text    = "Text"
    case wifi    = "WiFi"
    case contact = "Contact"
    case email   = "Email"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .url:     return "link"
        case .text:    return "text.alignleft"
        case .wifi:    return "wifi"
        case .contact: return "person.fill"
        case .email:   return "envelope.fill"
        }
    }

    var label: LocalizedStringKey { LocalizedStringKey(rawValue) }

    var accentColor: Color {
        switch self {
        case .url:     return Color(red: 0.55, green: 0.85, blue: 1.00)
        case .text:    return Color(red: 0.75, green: 0.65, blue: 1.00)
        case .wifi:    return Color(red: 0.40, green: 0.90, blue: 0.70)
        case .contact: return Color(red: 1.00, green: 0.75, blue: 0.35)
        case .email:   return Color(red: 1.00, green: 0.55, blue: 0.55)
        }
    }
}

// MARK: - WiFi Security

private enum WiFiSecurity: String, CaseIterable, Identifiable {
    case wpa  = "WPA/WPA2"
    case wep  = "WEP"
    case none = "None"

    var id: String { rawValue }
    var qrTag: String {
        switch self { case .wpa: return "WPA"; case .wep: return "WEP"; case .none: return "nopass" }
    }
}

// MARK: - View

struct QRCodeView: View {

    @State private var qrType: QRType = .url

    // URL
    @State private var urlText = ""
    // Text
    @State private var plainText = ""
    // WiFi
    @State private var wifiSSID = ""
    @State private var wifiPassword = ""
    @State private var wifiSecurity: WiFiSecurity = .wpa
    @State private var wifiHidden = false
    // Contact
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var contactOrg = ""
    // Email
    @State private var emailTo = ""
    @State private var emailSubject = ""
    @State private var emailBody = ""

    @State private var copied = false
    @FocusState private var focusedField: String?

    // MARK: Payload

    private var payload: String {
        switch qrType {
        case .url:
            let url = urlText.trimmingCharacters(in: .whitespaces)
            if url.isEmpty { return "" }
            return url.hasPrefix("http") ? url : "https://\(url)"
        case .text:
            return plainText
        case .wifi:
            guard !wifiSSID.isEmpty else { return "" }
            let pass = wifiSecurity == .none ? "" : wifiPassword
            let hidden = wifiHidden ? "H:true;" : ""
            return "WIFI:S:\(wifiSSID);T:\(wifiSecurity.qrTag);P:\(pass);\(hidden);"
        case .contact:
            guard !contactName.isEmpty else { return "" }
            var lines = ["BEGIN:VCARD", "VERSION:3.0", "FN:\(contactName)"]
            if !contactPhone.isEmpty   { lines.append("TEL:\(contactPhone)") }
            if !contactEmail.isEmpty   { lines.append("EMAIL:\(contactEmail)") }
            if !contactOrg.isEmpty     { lines.append("ORG:\(contactOrg)") }
            lines.append("END:VCARD")
            return lines.joined(separator: "\n")
        case .email:
            guard !emailTo.isEmpty else { return "" }
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = emailTo
            var items: [URLQueryItem] = []
            if !emailSubject.isEmpty { items.append(URLQueryItem(name: "subject", value: emailSubject)) }
            if !emailBody.isEmpty    { items.append(URLQueryItem(name: "body",    value: emailBody)) }
            if !items.isEmpty { components.queryItems = items }
            return components.string ?? "mailto:\(emailTo)"
        }
    }

    // MARK: QR Generation

    private func generateQR(from string: String) -> UIImage? {
        guard !string.isEmpty, let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale: CGFloat = 320 / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var qrImage: UIImage? { generateQR(from: payload) }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 16) {
                    GlassEffectContainer { headerCard }
                    typePicker
                    GlassEffectContainer { inputForm }
                    if let img = qrImage {
                        GlassEffectContainer { qrDisplay(img) }
                        actionBar(img)
                    } else {
                        GlassEffectContainer { emptyState }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focusedField = nil }
        }
        .navigationTitle("QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: qrType) { _, _ in
            focusedField = nil
            copied = false
        }
    }

    // MARK: - Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.18, green: 0.06, blue: 0.42),
                Color(red: 0.22, green: 0.08, blue: 0.50),
                Color(red: 0.16, green: 0.05, blue: 0.40),
                Color(red: 0.20, green: 0.07, blue: 0.44),
                Color(red: 0.28, green: 0.10, blue: 0.55),
                Color(red: 0.18, green: 0.06, blue: 0.46),
                Color(red: 0.14, green: 0.04, blue: 0.36),
                Color(red: 0.18, green: 0.06, blue: 0.42),
                Color(red: 0.15, green: 0.04, blue: 0.38)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.65, green: 0.50, blue: 1.00).opacity(0.22))
                    .frame(width: 52, height: 52)
                Image(systemName: "qrcode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.75, blue: 1.00),
                                     Color(red: 0.55, green: 0.35, blue: 1.00)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("QR Code Generator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("URL · Text · WiFi · Contact · Email")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { resetFields() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                ForEach(QRType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            qrType = type
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16, weight: .semibold))
                            Text(type.label)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(qrType == type ? type.accentColor : .white.opacity(0.38))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            qrType == type
                                ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white.opacity(0.14))
                                : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Input Form

    @ViewBuilder
    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch qrType {
            case .url:     urlForm
            case .text:    textForm
            case .wifi:    wifiForm
            case .contact: contactForm
            case .email:   emailForm
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // URL
    private var urlForm: some View {
        formField(id: "url", label: "Website or Link", icon: "link",
                  placeholder: "https://example.com", text: $urlText,
                  keyboard: .URL, accent: QRType.url.accentColor)
    }

    // Plain text
    private var textForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel("Enter Text", icon: "text.alignleft", accent: QRType.text.accentColor)
            TextEditor(text: $plainText)
                .font(.body.monospacedDigit())
                .foregroundStyle(.white)
                .tint(QRType.text.accentColor)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 180)
        }
    }

    // WiFi
    private var wifiForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            formField(id: "ssid", label: "Network Name (SSID)", icon: "wifi",
                      placeholder: "MyNetwork", text: $wifiSSID,
                      keyboard: .default, accent: QRType.wifi.accentColor)

            if wifiSecurity != .none {
                formField(id: "wifipass", label: "Password", icon: "lock.fill",
                          placeholder: "••••••••", text: $wifiPassword,
                          keyboard: .default, accent: QRType.wifi.accentColor,
                          secure: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                formLabel("Security", icon: "lock.shield", accent: QRType.wifi.accentColor)
                HStack(spacing: 8) {
                    ForEach(WiFiSecurity.allCases) { sec in
                        Button {
                            withAnimation(.spring(response: 0.25)) { wifiSecurity = sec }
                        } label: {
                            Text(sec.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(wifiSecurity == sec ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(wifiSecurity == sec
                                              ? QRType.wifi.accentColor
                                              : Color.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle(isOn: $wifiHidden) {
                Label("Hidden Network", systemImage: "eye.slash")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.80))
            }
            .toggleStyle(SwitchToggleStyle(tint: QRType.wifi.accentColor))
        }
    }

    // Contact (vCard)
    private var contactForm: some View {
        VStack(spacing: 14) {
            formField(id: "cname", label: "Full Name", icon: "person.fill",
                      placeholder: "Jane Doe", text: $contactName,
                      keyboard: .default, accent: QRType.contact.accentColor)
            formField(id: "cphone", label: "Phone Number", icon: "phone.fill",
                      placeholder: "+1 555 123 4567", text: $contactPhone,
                      keyboard: .phonePad, accent: QRType.contact.accentColor)
            formField(id: "cemail", label: "Email Address", icon: "envelope.fill",
                      placeholder: "jane@example.com", text: $contactEmail,
                      keyboard: .emailAddress, accent: QRType.contact.accentColor)
            formField(id: "corg", label: "Organization", icon: "building.2.fill",
                      placeholder: "Acme Corp (optional)", text: $contactOrg,
                      keyboard: .default, accent: QRType.contact.accentColor)
        }
    }

    // Email
    private var emailForm: some View {
        VStack(spacing: 14) {
            formField(id: "eto", label: "To", icon: "envelope.fill",
                      placeholder: "recipient@example.com", text: $emailTo,
                      keyboard: .emailAddress, accent: QRType.email.accentColor)
            formField(id: "esubj", label: "Subject", icon: "text.cursor",
                      placeholder: "Hello!", text: $emailSubject,
                      keyboard: .default, accent: QRType.email.accentColor)
            VStack(alignment: .leading, spacing: 6) {
                formLabel("Message", icon: "text.bubble", accent: QRType.email.accentColor)
                TextEditor(text: $emailBody)
                    .font(.body)
                    .foregroundStyle(.white)
                    .tint(QRType.email.accentColor)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 140)
            }
        }
    }

    // MARK: - QR Display

    @ViewBuilder
    private func qrDisplay(_ image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
                )

            Text(payload)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.50))
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)

            Text("\(payload.count) characters")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .glassEffect(
            .regular.tint(qrType.accentColor.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    // MARK: - Action Bar

    @ViewBuilder
    private func actionBar(_ image: UIImage) -> some View {
        HStack(spacing: 12) {
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview("QR Code", image: Image(uiImage: image))
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glass)

            Button {
                UIPasteboard.general.image = image
                withAnimation(.spring(response: 0.25)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                Label(copied ? "Copied!" : "Copy",
                      systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(copied ? Color(red: 0.40, green: 1.00, blue: 0.60) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "qrcode")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white.opacity(0.30))
            Text("Fill in the fields above to generate a QR code")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.38))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formLabel(_ label: LocalizedStringKey, icon: String, accent: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent.opacity(0.85))
    }

    @ViewBuilder
    private func formField(
        id: String,
        label: LocalizedStringKey,
        icon: String,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        accent: Color,
        secure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel(label, icon: icon, accent: accent)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .focused($focusedField, equals: id)
            .font(.body.weight(.medium))
            .foregroundStyle(.white)
            .tint(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
        }
    }

    private func resetFields() {
        urlText = ""; plainText = ""
        wifiSSID = ""; wifiPassword = ""; wifiSecurity = .wpa; wifiHidden = false
        contactName = ""; contactPhone = ""; contactEmail = ""; contactOrg = ""
        emailTo = ""; emailSubject = ""; emailBody = ""
        copied = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QRCodeView()
    }
}
