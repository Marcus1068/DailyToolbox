/*

Copyright 2020-2026 Marcus Deuß

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
//  ColorPickerView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - ColorPickerView

struct ColorPickerView: View {

    // MARK: - State

    @State private var rgb: (r: CGFloat, g: CGFloat, b: CGFloat)? = nil
    @State private var hexText = ""
    @State private var redText   = ""
    @State private var greenText = ""
    @State private var blueText  = ""
    @State private var hueText   = ""
    @State private var satText   = ""
    @State private var briText   = ""
    @State private var cyanText   = ""
    @State private var magText    = ""
    @State private var yellowText = ""
    @State private var blackText  = ""
    @FocusState private var focusedId: String?

    @State private var hexCopied  = false
    @State private var rgbCopied  = false
    @State private var hsbCopied  = false
    @State private var cmykCopied = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Accent Colors (adaptive: light tones in dark mode, saturated/dark in light mode)

    private var hexAccent:  Color {
        colorScheme == .dark ? Color(red: 0.85, green: 0.75, blue: 1.00)
                             : Color(red: 0.45, green: 0.15, blue: 0.80)
    }
    private var rgbAccent:  Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.55, blue: 0.55)
                             : Color(red: 0.80, green: 0.08, blue: 0.08)
    }
    private var hsbAccent:  Color {
        colorScheme == .dark ? Color(red: 0.55, green: 0.85, blue: 1.00)
                             : Color(red: 0.08, green: 0.45, blue: 0.85)
    }
    private var cmykAccent: Color {
        colorScheme == .dark ? Color(red: 0.45, green: 0.95, blue: 0.65)
                             : Color(red: 0.05, green: 0.58, blue: 0.32)
    }
    private var copiedColor: Color {
        colorScheme == .dark ? Color(red: 0.40, green: 1.00, blue: 0.60)
                             : Color(red: 0.05, green: 0.58, blue: 0.32)
    }

    // MARK: - Derived

    private var currentColor: Color? {
        guard let c = rgb else { return nil }
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    private var rgbCopyString:  String { "R:\(redText), G:\(greenText), B:\(blueText)" }
    private var hsbCopyString:  String { "H:\(hueText)°, S:\(satText)%, B:\(briText)%" }
    private var cmykCopyString: String { "C:\(cyanText)%, M:\(magText)%, Y:\(yellowText)%, K:\(blackText)%" }

    // MARK: - Input Filters

    private func hexOnly(_ s: String) -> String {
        var result = ""
        for c in s {
            if c == "#" {
                if result.isEmpty { result.append(c) }
            } else if "0123456789abcdefABCDEF".contains(c) {
                result.append(c)
            }
        }
        return String(result.prefix(7))
    }

    private func numericOnly(_ s: String) -> String {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        var dotSeen = false
        return String(normalized.filter { c in
            if c == "." {
                guard !dotSeen else { return false }
                dotSeen = true; return true
            }
            return c.isNumber
        })
    }

    // MARK: - Reset

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rgb = nil
            hexText = ""
            redText = ""; greenText = ""; blueText = ""
            hueText = ""; satText = ""; briText = ""
            cyanText = ""; magText = ""; yellowText = ""; blackText = ""
        }
        focusedId = nil
    }

    // MARK: - Clipboard

    private func copyToClipboard(_ text: String, feedback: @escaping (Bool) -> Void) {
        UIPasteboard.general.string = text
        withAnimation { feedback(true) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation { feedback(false) }
        }
    }

    // MARK: - Core Conversion

    private func updateFromRGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, skip group: String) {
        rgb = (r: r, g: g, b: b)

        if group != "hex" {
            hexText = String(format: "#%02X%02X%02X",
                             Int((r * 255).rounded()),
                             Int((g * 255).rounded()),
                             Int((b * 255).rounded()))
        }

        if group != "rgb" {
            redText   = "\(Int((r * 255).rounded()))"
            greenText = "\(Int((g * 255).rounded()))"
            blueText  = "\(Int((b * 255).rounded()))"
        }

        if group != "hsb" {
            var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
            UIColor(red: r, green: g, blue: b, alpha: 1)
                .getHue(&h, saturation: &s, brightness: &br, alpha: nil)
            hueText = String(format: "%.1f", h  * 360)
            satText = String(format: "%.1f", s  * 100)
            briText = String(format: "%.1f", br * 100)
        }

        if group != "cmyk" {
            let k = 1 - max(r, g, b)
            if k >= 1.0 {
                cyanText = "0.0"; magText = "0.0"; yellowText = "0.0"; blackText = "100.0"
            } else {
                cyanText   = String(format: "%.1f", (1 - r - k) / (1 - k) * 100)
                magText    = String(format: "%.1f", (1 - g - k) / (1 - k) * 100)
                yellowText = String(format: "%.1f", (1 - b - k) / (1 - k) * 100)
                blackText  = String(format: "%.1f", k * 100)
            }
        }
    }

    // MARK: - Parse Functions

    private func parseHex() {
        let stripped = hexText.hasPrefix("#") ? String(hexText.dropFirst()) : hexText
        let hex = String(stripped.prefix(6))
        guard hex.count == 6,
              let r8 = UInt8(hex.prefix(2), radix: 16),
              let g8 = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let b8 = UInt8(hex.dropFirst(4).prefix(2), radix: 16)
        else { rgb = nil; return }
        updateFromRGB(CGFloat(r8) / 255, CGFloat(g8) / 255, CGFloat(b8) / 255, skip: "hex")
    }

    private func parseRGB() {
        guard let rv = Double(numericOnly(redText)),
              let gv = Double(numericOnly(greenText)),
              let bv = Double(numericOnly(blueText))
        else { return }
        updateFromRGB(
            CGFloat(min(255, max(0, rv))) / 255,
            CGFloat(min(255, max(0, gv))) / 255,
            CGFloat(min(255, max(0, bv))) / 255,
            skip: "rgb"
        )
    }

    private func parseHSB() {
        guard let hv = Double(numericOnly(hueText)),
              let sv = Double(numericOnly(satText)),
              let bv = Double(numericOnly(briText))
        else { return }
        let h  = CGFloat(max(0, min(360, hv))) / 360
        let s  = CGFloat(max(0, min(100, sv))) / 100
        let br = CGFloat(max(0, min(100, bv))) / 100
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(hue: h, saturation: s, brightness: br, alpha: 1)
            .getRed(&r, green: &g, blue: &b, alpha: nil)
        updateFromRGB(r, g, b, skip: "hsb")
    }

    private func parseCMYK() {
        guard let cv = Double(numericOnly(cyanText)),
              let mv = Double(numericOnly(magText)),
              let yv = Double(numericOnly(yellowText)),
              let kv = Double(numericOnly(blackText))
        else { return }
        let c = CGFloat(min(100, max(0, cv))) / 100
        let m = CGFloat(min(100, max(0, mv))) / 100
        let y = CGFloat(min(100, max(0, yv))) / 100
        let k = CGFloat(min(100, max(0, kv))) / 100
        updateFromRGB((1 - c) * (1 - k), (1 - m) * (1 - k), (1 - y) * (1 - k), skip: "cmyk")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 16) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { hexCard }
                    GlassEffectContainer { rgbCard }
                    GlassEffectContainer { hsbCard }
                    GlassEffectContainer { cmykCard }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focusedId = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Color Converter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                Color(red: 0.06, green: 0.06, blue: 0.18),
                Color(red: 0.08, green: 0.08, blue: 0.22),
                Color(red: 0.06, green: 0.06, blue: 0.20),
                Color(red: 0.08, green: 0.07, blue: 0.20),
                Color(red: 0.10, green: 0.08, blue: 0.26),
                Color(red: 0.07, green: 0.06, blue: 0.22),
                Color(red: 0.05, green: 0.05, blue: 0.16),
                Color(red: 0.07, green: 0.06, blue: 0.20),
                Color(red: 0.05, green: 0.05, blue: 0.18)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(currentColor ?? Color.primary.opacity(0.08))
                    .frame(width: 52, height: 52)
                if rgb == nil {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.35), Color.primary.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 52, height: 52)
                }
            }
            .animation(.spring(response: 0.4), value: rgb?.r)

            VStack(alignment: .leading, spacing: 4) {
                Text("Color Converter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("HEX · RGB · HSB · CMYK")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.75))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - HEX Card

    private var hexCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HEX")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hexAccent)
                Spacer()
                Button {
                    copyToClipboard(hexText) { hexCopied = $0 }
                } label: {
                    Text(hexCopied ? "✓" : "Copy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hexCopied ? copiedColor : hexAccent.opacity(0.75))
                        .frame(minWidth: 44)
                }
                .buttonStyle(.plain)
                .disabled(hexText.isEmpty)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("#RRGGBB")
                    .font(.caption2)
                    .foregroundStyle(hexAccent.opacity(0.7))
                TextField("#000000", text: $hexText)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedId, equals: "hex")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(hexAccent)
                    .onChange(of: hexText) { _, newVal in
                        guard focusedId == "hex" else { return }
                        let filtered = hexOnly(newVal)
                        if filtered != newVal { hexText = filtered; return }
                        parseHex()
                    }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - RGB Card

    private var rgbCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RGB (0–255)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(rgbAccent)
                Spacer()
                Button {
                    copyToClipboard(rgbCopyString) { rgbCopied = $0 }
                } label: {
                    Text(rgbCopied ? "✓" : "Copy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(rgbCopied ? copiedColor : rgbAccent.opacity(0.75))
                        .frame(minWidth: 44)
                }
                .buttonStyle(.plain)
                .disabled(redText.isEmpty || greenText.isEmpty || blueText.isEmpty)
            }

            HStack(spacing: 12) {
                colorField(label: "R", placeholder: "0", text: $redText,
                           fieldId: "rgb-r", accent: rgbAccent, guardPrefix: "rgb-") { parseRGB() }
                colorField(label: "G", placeholder: "0", text: $greenText,
                           fieldId: "rgb-g", accent: rgbAccent, guardPrefix: "rgb-") { parseRGB() }
                colorField(label: "B", placeholder: "0", text: $blueText,
                           fieldId: "rgb-b", accent: rgbAccent, guardPrefix: "rgb-") { parseRGB() }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - HSB Card

    private var hsbCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HSB")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hsbAccent)
                Spacer()
                Button {
                    copyToClipboard(hsbCopyString) { hsbCopied = $0 }
                } label: {
                    Text(hsbCopied ? "✓" : "Copy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hsbCopied ? copiedColor : hsbAccent.opacity(0.75))
                        .frame(minWidth: 44)
                }
                .buttonStyle(.plain)
                .disabled(hueText.isEmpty || satText.isEmpty || briText.isEmpty)
            }

            HStack(spacing: 12) {
                colorField(label: "H°", placeholder: "0.0", text: $hueText,
                           fieldId: "hsb-h", accent: hsbAccent, guardPrefix: "hsb-") { parseHSB() }
                colorField(label: "S%", placeholder: "0.0", text: $satText,
                           fieldId: "hsb-s", accent: hsbAccent, guardPrefix: "hsb-") { parseHSB() }
                colorField(label: "B%", placeholder: "0.0", text: $briText,
                           fieldId: "hsb-b", accent: hsbAccent, guardPrefix: "hsb-") { parseHSB() }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - CMYK Card

    private var cmykCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CMYK (%)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(cmykAccent)
                Spacer()
                Button {
                    copyToClipboard(cmykCopyString) { cmykCopied = $0 }
                } label: {
                    Text(cmykCopied ? "✓" : "Copy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(cmykCopied ? copiedColor : cmykAccent.opacity(0.75))
                        .frame(minWidth: 44)
                }
                .buttonStyle(.plain)
                .disabled(cyanText.isEmpty || magText.isEmpty || yellowText.isEmpty || blackText.isEmpty)
            }

            HStack(spacing: 8) {
                colorField(label: "C", placeholder: "0.0", text: $cyanText,
                           fieldId: "cmyk-c", accent: cmykAccent, guardPrefix: "cmyk-") { parseCMYK() }
                colorField(label: "M", placeholder: "0.0", text: $magText,
                           fieldId: "cmyk-m", accent: cmykAccent, guardPrefix: "cmyk-") { parseCMYK() }
                colorField(label: "Y", placeholder: "0.0", text: $yellowText,
                           fieldId: "cmyk-y", accent: cmykAccent, guardPrefix: "cmyk-") { parseCMYK() }
                colorField(label: "K", placeholder: "0.0", text: $blackText,
                           fieldId: "cmyk-k", accent: cmykAccent, guardPrefix: "cmyk-") { parseCMYK() }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Shared Field Builder

    @ViewBuilder
    private func colorField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        fieldId: String,
        accent: Color,
        guardPrefix: String,
        onChange parseGroup: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(accent.opacity(0.7))
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .focused($focusedId, equals: fieldId)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.primary)
                .tint(accent)
                .onChange(of: text.wrappedValue) { _, newVal in
                    guard focusedId?.hasPrefix(guardPrefix) == true else { return }
                    let filtered = numericOnly(newVal)
                    if filtered != newVal { text.wrappedValue = filtered; return }
                    parseGroup()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ColorPickerView()
    }
}
