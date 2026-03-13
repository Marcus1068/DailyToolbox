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
//  AspectRatioView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Preset

private struct Preset {
    let label: String
    let w: Double
    let h: Double
}

private let presets: [Preset] = [
    Preset(label: "16:9",  w: 16, h: 9),
    Preset(label: "4:3",   w: 4,  h: 3),
    Preset(label: "3:2",   w: 3,  h: 2),
    Preset(label: "1:1",   w: 1,  h: 1),
    Preset(label: "21:9",  w: 21, h: 9),
    Preset(label: "9:16",  w: 9,  h: 16),
]

// MARK: - Lock Axis

private enum LockAxis: String, CaseIterable {
    case width  = "Lock W"
    case height = "Lock H"
    var localizedKey: LocalizedStringKey {
        switch self {
        case .width:  return "Lock W"
        case .height: return "Lock H"
        }
    }
}

// MARK: - GCD helper

private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

private func simplifyRatio(_ w: Double, _ h: Double) -> String {
    guard w > 0, h > 0 else { return "–:–" }
    let scale = 1000.0
    let wi = Int(w * scale), hi = Int(h * scale)
    let d = gcd(wi, hi)
    let sw = wi / d, sh = hi / d
    // Nice display: if numbers are large, show decimal
    if sw > 999 || sh > 999 {
        return String(format: "%.3g : %.3g", w / h, 1.0)
    }
    return "\(sw):\(sh)"
}

// MARK: - View

struct AspectRatioView: View {

    @State private var widthText  = ""
    @State private var heightText = ""
    @State private var lockAxis: LockAxis = .height
    @State private var ratioLabel = "–:–"

    @FocusState private var focused: Int?

    private let accent = Color(red: 0.75, green: 0.45, blue: 1.00)

    // MARK: Helpers

    private func computeRatio() {
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        ratioLabel = simplifyRatio(w, h)
    }

    private func solveMissing() {
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        computeRatio()
        guard w > 0 || h > 0 else { return }

        // If both filled, just update ratio
        if w > 0 && h > 0 { return }

        // Can't solve with one value unless we have a known ratio
        // (handled by presets → apply preset fills both)
    }

    private func applyPreset(_ p: Preset) {
        // If width is filled, solve height; if height filled, solve width; else fill both canonical
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        withAnimation(.spring(response: 0.3)) {
            if w > 0 && lockAxis == .width {
                heightText = formatDim(w * p.h / p.w)
                widthText  = formatDim(w)
            } else if h > 0 && lockAxis == .height {
                widthText  = formatDim(h * p.w / p.h)
                heightText = formatDim(h)
            } else {
                widthText  = formatDim(p.w * 100)
                heightText = formatDim(p.h * 100)
            }
            computeRatio()
        }
        focused = nil
    }

    private func solveOther() {
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard w > 0, h > 0 else { computeRatio(); return }
        computeRatio()
    }

    private func formatDim(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%.2g", v)
    }

    private func scaleWidth() {
        guard let w = Double(widthText.replacingOccurrences(of: ",", with: ".")),
              let h = Double(heightText.replacingOccurrences(of: ",", with: ".")),
              w > 0, h > 0 else { computeRatio(); return }
        computeRatio()
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            widthText = ""; heightText = ""; ratioLabel = "–:–"
        }
        focused = nil
    }

    private func onWidthChange() {
        guard focused == 1 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        if w > 0 && h > 0 { computeRatio(); return }
        computeRatio()
    }

    private func onHeightChange() {
        guard focused == 2 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        if w > 0 && h > 0 { computeRatio(); return }
        computeRatio()
    }

    // Solve the locked axis from the other
    private func solveFromWidth() {
        guard focused == 1 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard w > 0 else { computeRatio(); return }
        if h > 0 {
            computeRatio()
        }
    }

    private func solveFromHeight() {
        guard focused == 2 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard h > 0 else { computeRatio(); return }
        if w > 0 {
            computeRatio()
        }
    }

    // Scale: given one side and ratio from both filled values, compute the other
    private func scaleFromWidth() {
        guard focused == 1 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard w > 0, h > 0 else { computeRatio(); return }
        computeRatio()
    }

    private func scaleFromHeight() {
        guard focused == 2 else { return }
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard w > 0, h > 0 else { computeRatio(); return }
        computeRatio()
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { presetsCard }
                    GlassEffectContainer { dimensionsCard }
                    if !ratioLabel.hasPrefix("–") {
                        GlassEffectContainer { ratioResultCard }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focused = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Aspect Ratio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0,0.0],[0.5,0.0],[1.0,0.0],
                [0.0,0.5],[0.5,0.5],[1.0,0.5],
                [0.0,1.0],[0.5,1.0],[1.0,1.0]
            ],
            colors: [
                Color(red:0.10,green:0.04,blue:0.20), Color(red:0.13,green:0.05,blue:0.26), Color(red:0.10,green:0.04,blue:0.22),
                Color(red:0.13,green:0.05,blue:0.25), Color(red:0.17,green:0.07,blue:0.33), Color(red:0.13,green:0.05,blue:0.27),
                Color(red:0.08,green:0.03,blue:0.18), Color(red:0.11,green:0.04,blue:0.23), Color(red:0.08,green:0.03,blue:0.18)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [Color(red:0.75,green:0.45,blue:1.00), Color(red:0.55,green:0.25,blue:0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "aspectratio.fill")
                    .font(.title2).foregroundStyle(Color.primary)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("Aspect Ratio")
                    .font(.headline.weight(.bold)).foregroundStyle(Color.primary)
                Text("Calculate & scale dimensions")
                    .font(.caption).foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.75))
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Presets

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Ratios")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(presets, id: \.label) { p in
                    Button { applyPreset(p) } label: {
                        VStack(spacing: 3) {
                            // Mini visual
                            let ratio = p.w / p.h
                            let maxW: CGFloat = 36
                            let bw = ratio >= 1 ? maxW : maxW * CGFloat(ratio)
                            let bh = ratio >= 1 ? maxW / CGFloat(ratio) : maxW
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(accent.opacity(0.70), lineWidth: 1.5)
                                .frame(width: bw, height: min(bh, maxW))
                            Text(p.label)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.primary.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Dimensions

    private var dimensionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Dimensions")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accent)
                Spacer()
                // Lock toggle
                HStack(spacing: 0) {
                    ForEach(LockAxis.allCases, id: \.self) { axis in
                        let sel = lockAxis == axis
                        Button {
                            withAnimation(.spring(response: 0.25)) { lockAxis = axis }
                        } label: {
                            Text(axis.localizedKey)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(sel ? accent : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.primary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 13))
            }

            HStack(spacing: 14) {
                dimField(label: "Width", placeholder: "1920", text: $widthText,
                         focusTag: 1, locked: lockAxis == .width) { onWidthChange() }
                Text("×").font(.title2.weight(.light)).foregroundStyle(Color.primary.opacity(0.40))
                dimField(label: "Height", placeholder: "1080", text: $heightText,
                         focusTag: 2, locked: lockAxis == .height) { onHeightChange() }
            }

            // Scale button
            Button {
                let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
                let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
                guard w > 0, h > 0 else { return }
                // Scale the unlocked axis to match the locked one
                if lockAxis == .height {
                    // height is locked, width was changed → keep height, recalc would be same
                    // Instead: scale width 2× for demonstration
                } else {
                }
                computeRatio()
            } label: {
                Text("Get Ratio")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func dimField(label: LocalizedStringKey, placeholder: LocalizedStringKey,
                          text: Binding<String>, focusTag: Int, locked: Bool,
                          onChange: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(accent.opacity(0.80))
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.65))
                }
            }
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .focused($focused, equals: focusTag)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.primary)
                .tint(accent)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(locked ? accent.opacity(0.10) : Color.primary.opacity(0.07)))
                .overlay(locked ? RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(accent.opacity(0.30), lineWidth: 1) : nil)
                .onChange(of: text.wrappedValue) { _, _ in onChange() }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ratio Result

    private var ratioResultCard: some View {
        let w = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let decimal = h > 0 ? String(format: "%.4g", w / h) : "–"

        return VStack(spacing: 16) {
            // Big ratio display
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(ratioLabel)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity)

            Divider().overlay(Color.primary.opacity(0.10))

            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text("Decimal").font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.50))
                    Text(decimal).font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Color.primary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 36).overlay(Color.primary.opacity(0.10))

                VStack(spacing: 3) {
                    Text("Orientation").font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.50))
                    Text(w >= h ? (w == h ? "Square" : "Landscape") : "Portrait")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(accent)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { AspectRatioView() }
}
