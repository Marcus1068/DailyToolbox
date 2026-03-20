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
//  AreaVolumeView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Shape Model

private enum Geometry: String, CaseIterable {
    case rectangle, circle, triangle, cylinder, sphere, cone

    var localizedKey: LocalizedStringKey {
        switch self {
        case .rectangle: return "Rectangle"
        case .circle:    return "Circle"
        case .triangle:  return "Triangle"
        case .cylinder:  return "Cylinder"
        case .sphere:    return "Sphere"
        case .cone:      return "Cone"
        }
    }

    var systemImage: String {
        switch self {
        case .rectangle: return "rectangle"
        case .circle:    return "circle"
        case .triangle:  return "triangle"
        case .cylinder:  return "cylinder"
        case .sphere:    return "circle.circle"
        case .cone:      return "cone"
        }
    }

    var is3D: Bool { self == .cylinder || self == .sphere || self == .cone }

    var info: (formula: LocalizedStringKey, areaLabel: LocalizedStringKey?, volumeLabel: LocalizedStringKey?) {
        switch self {
        case .rectangle: return ("A = w × h", "Area", nil)
        case .circle:    return ("A = π r²", "Area", nil)
        case .triangle:  return ("A = ½ b × h", "Area", nil)
        case .cylinder:  return ("A = 2πr² + 2πrh   V = πr²h", "Surface Area", "Volume")
        case .sphere:    return ("A = 4πr²   V = ⁴⁄₃ π r³", "Surface Area", "Volume")
        case .cone:      return ("A = πr(r+√(r²+h²))   V = ⅓ π r² h", "Surface Area", "Volume")
        }
    }
}

// MARK: - Calculation Result

private struct CalcResult {
    var area: Double
    var volume: Double?
    var perimeter: Double?

    var areaString:      String  { formatted(area) }
    var volumeString:    String? { volume.map    { formatted($0) } }
    var perimeterString: String? { perimeter.map { formatted($0) } }

    private func formatted(_ v: Double) -> String {
        if abs(v) == 0 { return "0" }
        if abs(v) >= 1e6 || (abs(v) < 0.001 && abs(v) > 0) {
            return String(format: "%.4e", v)
        }
        return String(format: "%.6g", v)
    }
}

// MARK: - Length Unit

private enum LengthUnit: String, CaseIterable, Identifiable {
    case m = "m", cm = "cm", mm = "mm", inch = "in", ft = "ft"
    var id: String { rawValue }
    var areaSymbol:   String { self == .inch ? "in²" : "\(rawValue)²" }
    var volumeSymbol: String { self == .inch ? "in³" : "\(rawValue)³" }
}

// MARK: - View

struct AreaVolumeView: View {

    @State private var shape: Geometry = .rectangle

    @State private var field1 = ""
    @State private var field2 = ""
    @FocusState private var focused: Int?

    @State private var result: CalcResult? = nil
    @State private var unit:   LengthUnit   = .m

    private var field1LabelActual: LocalizedStringKey {
        switch shape {
        case .rectangle: return "Width (w)"
        case .triangle:  return "Base (b)"
        default:         return "Radius (r)"
        }
    }

    private var field2Label: LocalizedStringKey? {
        switch shape {
        case .circle, .sphere: return nil
        default: return "Height (h)"
        }
    }

    private func calculate() {
        let v1 = Double(field1.replacingOccurrences(of: ",", with: ".")) ?? 0
        let v2 = Double(field2.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard v1 > 0 else { result = nil; return }

        switch shape {
        case .rectangle:
            guard v2 > 0 else { result = nil; return }
            result = CalcResult(area: v1 * v2, perimeter: 2 * (v1 + v2))
        case .circle:
            result = CalcResult(area: .pi * v1 * v1, perimeter: 2 * .pi * v1)
        case .triangle:
            guard v2 > 0 else { result = nil; return }
            let slant = sqrt((v1 / 2) * (v1 / 2) + v2 * v2)
            result = CalcResult(area: 0.5 * v1 * v2, perimeter: v1 + 2 * slant)
        case .cylinder:
            guard v2 > 0 else { result = nil; return }
            let r = v1, h = v2
            result = CalcResult(area: 2 * .pi * r * r + 2 * .pi * r * h, volume: .pi * r * r * h)
        case .sphere:
            let r = v1
            result = CalcResult(area: 4 * .pi * r * r, volume: (4.0 / 3.0) * .pi * r * r * r)
        case .cone:
            guard v2 > 0 else { result = nil; return }
            let r = v1, h = v2
            result = CalcResult(area: .pi * r * (r + sqrt(r * r + h * h)), volume: (1.0 / 3.0) * .pi * r * r * h)
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) { field1 = ""; field2 = ""; result = nil }
        focused = nil
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { shapePickerCard }
                    GlassEffectContainer { inputCard }
                    if let result {
                        GlassEffectContainer { resultCard(result) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focused = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Area & Volume")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: shape) { _, _ in clearAll() }
    }

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0,0.0],[0.5,0.0],[1.0,0.0],
                [0.0,0.5],[0.5,0.5],[1.0,0.5],
                [0.0,1.0],[0.5,1.0],[1.0,1.0]
            ],
            colors: [
                Color(red:0.04,green:0.14,blue:0.06), Color(red:0.05,green:0.17,blue:0.07), Color(red:0.04,green:0.14,blue:0.06),
                Color(red:0.05,green:0.18,blue:0.07), Color(red:0.07,green:0.22,blue:0.09), Color(red:0.05,green:0.17,blue:0.08),
                Color(red:0.03,green:0.12,blue:0.05), Color(red:0.04,green:0.15,blue:0.07), Color(red:0.03,green:0.12,blue:0.05)
            ]
        )
        .ignoresSafeArea()
    }

    private var shapePickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shape")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Geometry.allCases, id: \.self) { geo in
                    let selected = shape == geo
                    Button {
                        withAnimation(.spring(response: 0.3)) { shape = geo }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: geo.systemImage)
                                .font(.title2)
                                .foregroundStyle(selected
                                    ? Color(red:0.55,green:1.00,blue:0.65)
                                    : Color.primary.opacity(0.55))
                            Text(geo.localizedKey)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected
                                    ? Color(red:0.55,green:1.00,blue:0.65).opacity(0.18)
                                    : Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(selected
                                    ? Color(red:0.55,green:1.00,blue:0.65).opacity(0.55)
                                    : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(shape.info.formula)
                .font(.caption.monospaced())
                .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65).opacity(0.80))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Dimensions")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65))
                Spacer()
                Picker("Unit", selection: $unit) {
                    ForEach(LengthUnit.allCases) { u in Text(u.rawValue).tag(u) }
                }
                .pickerStyle(.menu)
                .tint(Color(red:0.55,green:1.00,blue:0.65))
                Button(action: clearAll) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.70))
                }
                .buttonStyle(.glass)
            }

            dimField(label: field1LabelActual, text: $field1, focusTag: 1)

            if field2Label != nil {
                dimField(label: field2Label!, text: $field2, focusTag: 2)
            }

            Button(action: calculate) {
                Text("Calculate")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red:0.55,green:1.00,blue:0.65))
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func dimField(label: LocalizedStringKey, text: Binding<String>, focusTag: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65).opacity(0.70))
            HStack(spacing: 8) {
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: focusTag)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(Color(red:0.55,green:1.00,blue:0.65))
                    .onChange(of: text.wrappedValue) { _, _ in
                        guard self.focused == focusTag else { return }
                        calculate()
                    }
                Text(unit.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65).opacity(0.65))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.07))
            )
        }
    }

    @ViewBuilder
    private func resultCard(_ res: CalcResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Result")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65))

            if let p = res.perimeterString {
                let perimLabel: LocalizedStringKey = shape == .triangle ? "Perimeter (est.)" : "Perimeter"
                resultRow(label: perimLabel, value: p, unit: unit.rawValue)
                Divider().overlay(Color.primary.opacity(0.12))
            }

            resultRow(label: shape.info.areaLabel ?? "Area",
                      value: res.areaString,
                      unit: unit.areaSymbol)

            if let vol = res.volumeString, let lbl = shape.info.volumeLabel {
                Divider().overlay(Color.primary.opacity(0.12))
                resultRow(label: lbl, value: vol, unit: unit.volumeSymbol)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func resultRow(label: LocalizedStringKey, value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.60))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(red:0.55,green:1.00,blue:0.65))
                        .minimumScaleFactor(0.6)
                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.55))
                }
            }
            Spacer()
            Button {
                UIPasteboard.general.string = "\(value) \(unit)"
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            .buttonStyle(.glass)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AreaVolumeView()
    }
}
