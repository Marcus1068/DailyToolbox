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
//  BMIView.swift
//  DailyToolbox
//

import SwiftUI

private enum UnitSystem: String, CaseIterable {
    case metric = "Metric"; case imperial = "Imperial"
    var localizedKey: LocalizedStringKey {
        switch self { case .metric: return "Metric"; case .imperial: return "Imperial" }
    }
}

private enum BiologicalSex: String, CaseIterable {
    case male = "Male"; case female = "Female"
    var localizedKey: LocalizedStringKey {
        switch self { case .male: return "Male"; case .female: return "Female" }
    }
}

private struct BMICategory {
    let name: LocalizedStringKey
    let range: ClosedRange<Double>
    let color: Color

    @MainActor static let categories: [BMICategory] = [
        BMICategory(name: "Underweight",   range: 0...18.49,  color: Color(red: 0.35, green: 0.75, blue: 1.00)),
        BMICategory(name: "Normal weight", range: 18.5...24.99, color: Color(red: 0.35, green: 0.90, blue: 0.55)),
        BMICategory(name: "Overweight",    range: 25...29.99, color: Color(red: 1.00, green: 0.78, blue: 0.25)),
        BMICategory(name: "Obese",         range: 30...100,   color: Color(red: 1.00, green: 0.40, blue: 0.35)),
    ]
    @MainActor static func classify(_ bmi: Double) -> BMICategory {
        categories.first { $0.range.contains(bmi) } ?? categories.last!
    }
}

private struct BodyResult {
    let bmi: Double; let bmr: Double; let category: BMICategory
    let idealMin: Double; let idealMax: Double
    var bmiString: String { String(format: "%.1f", bmi) }
    static func ideal(heightM: Double) -> (Double, Double) { (18.5 * heightM * heightM, 24.9 * heightM * heightM) }
}

struct BMIView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var coralAccent: Color  { colorScheme == .dark ? Color(red: 0.95, green: 0.45, blue: 0.35) : Color(red: 0.82, green: 0.22, blue: 0.18) }
    private var salmonAccent: Color { colorScheme == .dark ? Color(red: 0.95, green: 0.60, blue: 0.25) : Color(red: 0.80, green: 0.42, blue: 0.08) }
    private var headerGradient: LinearGradient { LinearGradient(colors: [colorScheme == .dark ? Color(red:0.95,green:0.45,blue:0.35) : Color(red:0.78,green:0.20,blue:0.15), colorScheme == .dark ? Color(red:0.80,green:0.25,blue:0.20) : Color(red:0.62,green:0.10,blue:0.08)], startPoint: .topLeading, endPoint: .bottomTrailing) }

    @State private var units: UnitSystem = .metric
    @State private var sex: BiologicalSex = .male
    @State private var ageText = ""; @State private var heightText = ""; @State private var weightText = ""
    @State private var result: BodyResult? = nil
    @FocusState private var focused: Int?

    private var heightLabel: LocalizedStringKey { units == .metric ? "Height (cm)" : "Height (ft)" }
    private var weightLabel: LocalizedStringKey { units == .metric ? "Weight (kg)" : "Weight (lbs)" }
    private var heightPlaceholder: LocalizedStringKey { units == .metric ? "175" : "5.9" }
    private var weightPlaceholder: LocalizedStringKey { units == .metric ? "70" : "154" }

    private func calculate() {
        let age  = Double(ageText.replacingOccurrences(of: ",", with: "."))    ?? 0
        let hRaw = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let wRaw = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard hRaw > 0, wRaw > 0 else { result = nil; return }
        let heightM  = units == .metric ? hRaw / 100.0 : hRaw * 0.3048
        let weightKg = units == .metric ? wRaw : wRaw * 0.453592
        guard heightM > 0 else { result = nil; return }
        let bmi = weightKg / (heightM * heightM)
        let category = BMICategory.classify(bmi)
        let (idealMin, idealMax) = BodyResult.ideal(heightM: heightM)
        let bmr: Double
        if age > 0 {
            let hCm = heightM * 100
            bmr = sex == .male ? 10*weightKg + 6.25*hCm - 5*age + 5 : 10*weightKg + 6.25*hCm - 5*age - 161
        } else { bmr = 0 }
        withAnimation(.spring(response: 0.4)) {
            result = BodyResult(bmi: bmi, bmr: max(0, bmr), category: category, idealMin: idealMin, idealMax: idealMax)
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) { ageText = ""; heightText = ""; weightText = ""; result = nil }
        focused = nil
    }

    private func kgLbs(_ kg: Double) -> String {
        units == .metric ? String(format: "%.1f kg", kg) : String(format: "%.1f lbs", kg / 0.453592)
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { inputCard }
                    if let result {
                        GlassEffectContainer { bmiCard(result) }
                        if result.bmr > 0 { GlassEffectContainer { bmrCard(result) } }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 24)
            }
            .onTapGesture { focused = nil }
        }
        .navigationTitle("BMI Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: units) { _, _ in calculate() }
        .onChange(of: sex)   { _, _ in calculate() }
    }

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [[0.0,0.0],[0.5,0.0],[1.0,0.0],[0.0,0.5],[0.5,0.5],[1.0,0.5],[0.0,1.0],[0.5,1.0],[1.0,1.0]],
            colors: [
                Color(red:0.20,green:0.04,blue:0.06), Color(red:0.24,green:0.06,blue:0.07), Color(red:0.20,green:0.04,blue:0.06),
                Color(red:0.24,green:0.06,blue:0.07), Color(red:0.30,green:0.08,blue:0.09), Color(red:0.24,green:0.06,blue:0.08),
                Color(red:0.18,green:0.03,blue:0.05), Color(red:0.22,green:0.05,blue:0.07), Color(red:0.18,green:0.03,blue:0.05)
            ]
        ).ignoresSafeArea()
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(headerGradient)
                Image(systemName: "figure.stand").font(.title2).foregroundStyle(Color.primary)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("BMI & Body Metrics").font(.headline.weight(.bold)).foregroundStyle(Color.primary)
                Text("BMI · BMR · Ideal weight").font(.caption).foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.primary.opacity(0.75))
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Details").font(.subheadline.weight(.bold)).foregroundStyle(coralAccent)
            HStack(spacing: 10) {
                segmentedPicker(items: UnitSystem.allCases, selected: $units, label: \.localizedKey)
                segmentedPicker(items: BiologicalSex.allCases, selected: $sex, label: \.localizedKey)
            }
            HStack(spacing: 12) {
                bodyField(label: heightLabel, placeholder: heightPlaceholder, text: $heightText, focusTag: 1)
                bodyField(label: weightLabel, placeholder: weightPlaceholder, text: $weightText, focusTag: 2)
            }
            bodyField(label: "Age (optional, for BMR)", placeholder: "30", text: $ageText, focusTag: 3)
            Button(action: calculate) {
                Text("Calculate").font(.headline.weight(.bold)).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(coralAccent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func segmentedPicker<T: Hashable>(items: [T], selected: Binding<T>, label: KeyPath<T, LocalizedStringKey>) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                let sel = selected.wrappedValue == item
                Button {
                    withAnimation(.spring(response: 0.25)) { selected.wrappedValue = item }
                } label: {
                    Text(item[keyPath: label])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(sel ? coralAccent : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func bodyField(label: LocalizedStringKey, placeholder: LocalizedStringKey, text: Binding<String>, focusTag: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(coralAccent.opacity(0.80))
            TextField(placeholder, text: text).keyboardType(.decimalPad).focused($focused, equals: focusTag)
                .font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(Color.primary).tint(coralAccent)
                .padding(12).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.07)))
                .onChange(of: text.wrappedValue) { _, _ in guard focused == focusTag else { return }; calculate() }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func bmiCard(_ res: BodyResult) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                VStack(spacing: 4) {
                    Text("BMI").font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
                    Text(res.bmiString).font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(res.category.color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(res.category.name).font(.title3.weight(.bold)).foregroundStyle(res.category.color)
                    Text("Ideal weight: \(kgLbs(res.idealMin)) – \(kgLbs(res.idealMax))")
                        .font(.caption).foregroundStyle(Color.primary.opacity(0.60))
                }
                Spacer()
            }
            bmiScaleBar(bmi: res.bmi)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func bmiScaleBar(bmi: Double) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red:0.35,green:0.75,blue:1.00), Color(red:0.35,green:0.90,blue:0.55), Color(red:1.00,green:0.78,blue:0.25), Color(red:1.00,green:0.40,blue:0.35)]
                            : [Color(red:0.10,green:0.45,blue:0.88), Color(red:0.08,green:0.55,blue:0.28), Color(red:0.68,green:0.44,blue:0.00), Color(red:0.82,green:0.15,blue:0.10)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(height: 10).clipShape(Capsule())
                    let frac = CGFloat(min(max(bmi, 10), 40) - 10) / 30.0
                    Circle().fill(colorScheme == .dark ? Color.white : Color.black).frame(width: 14, height: 14).shadow(color: .black.opacity(0.4), radius: 3)
                        .offset(x: frac * geo.size.width - 7, y: -2)
                }
            }
            .frame(height: 14)
            HStack {
                Text("10").font(.system(size: 9)).foregroundStyle(Color.primary.opacity(0.40))
                Spacer(); Text("18.5").font(.system(size: 9)).foregroundStyle(Color.primary.opacity(0.40))
                Spacer(); Text("25").font(.system(size: 9)).foregroundStyle(Color.primary.opacity(0.40))
                Spacer(); Text("30").font(.system(size: 9)).foregroundStyle(Color.primary.opacity(0.40))
                Spacer(); Text("40").font(.system(size: 9)).foregroundStyle(Color.primary.opacity(0.40))
            }
        }
    }

    @ViewBuilder
    private func bmrCard(_ res: BodyResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basal Metabolic Rate").font(.subheadline.weight(.bold)).foregroundStyle(coralAccent)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.0f", res.bmr))
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(salmonAccent)
                Text("kcal/day").font(.subheadline.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
            }
            Text("Calories your body burns at rest (Mifflin-St Jeor)").font(.caption).foregroundStyle(Color.primary.opacity(0.45))
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    NavigationStack { BMIView() }
}
