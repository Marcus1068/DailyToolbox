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
//  UnitConverterView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Unit Entry

private struct UnitEntry: Identifiable {
    let id: String          // stable dictionary key
    let label: LocalizedStringKey
    let shortLabel: String
    let unit: Dimension
    let icon: String
    let accentColor: Color
}

// MARK: - Category

private enum UnitCategory: String, CaseIterable, Identifiable {
    case length = "Length"
    case weight = "Weight"
    case volume = "Volume"
    case speed  = "Speed"

    var id: String { rawValue }

    var label: LocalizedStringKey { LocalizedStringKey(rawValue) }

    var icon: String {
        switch self {
        case .length: return "ruler"
        case .weight: return "scalemass"
        case .volume: return "drop.fill"
        case .speed:  return "gauge.with.needle"
        }
    }

    var accentColor: Color {
        switch self {
        case .length: return Color(red: 0.35, green: 0.78, blue: 1.00)
        case .weight: return Color(red: 0.50, green: 0.92, blue: 0.45)
        case .volume: return Color(red: 0.35, green: 0.85, blue: 0.95)
        case .speed:  return Color(red: 1.00, green: 0.82, blue: 0.28)
        }
    }

    var units: [UnitEntry] {
        switch self {
        case .length:
            let c = Color(red: 0.35, green: 0.78, blue: 1.00)
            return [
                UnitEntry(id: "km",  label: "Kilometers",  shortLabel: "km",  unit: UnitLength.kilometers,  icon: "road.lanes",                  accentColor: c),
                UnitEntry(id: "m",   label: "Meters",      shortLabel: "m",   unit: UnitLength.meters,      icon: "arrow.left.and.right",        accentColor: c),
                UnitEntry(id: "cm",  label: "Centimeters", shortLabel: "cm",  unit: UnitLength.centimeters, icon: "pencil.and.ruler.fill",        accentColor: c),
                UnitEntry(id: "mm",  label: "Millimeters", shortLabel: "mm",  unit: UnitLength.millimeters, icon: "ruler.fill",                  accentColor: c),
                UnitEntry(id: "mi",  label: "Miles",       shortLabel: "mi",  unit: UnitLength.miles,       icon: "car.fill",                    accentColor: c),
                UnitEntry(id: "ft",  label: "Feet",        shortLabel: "ft",  unit: UnitLength.feet,        icon: "figure.walk",                 accentColor: c),
                UnitEntry(id: "in",  label: "Inches",      shortLabel: "in",  unit: UnitLength.inches,      icon: "lines.measurement.horizontal",accentColor: c),
                UnitEntry(id: "yd",  label: "Yards",       shortLabel: "yd",  unit: UnitLength.yards,       icon: "sportscourt.fill",            accentColor: c),
            ]
        case .weight:
            let c = Color(red: 0.50, green: 0.92, blue: 0.45)
            return [
                UnitEntry(id: "t",   label: "Tonnes",      shortLabel: "t",   unit: UnitMass.metricTons,  icon: "shippingbox.fill",  accentColor: c),
                UnitEntry(id: "kg",  label: "Kilograms",   shortLabel: "kg",  unit: UnitMass.kilograms,   icon: "scalemass.fill",    accentColor: c),
                UnitEntry(id: "g",   label: "Grams",       shortLabel: "g",   unit: UnitMass.grams,       icon: "scalemass",         accentColor: c),
                UnitEntry(id: "mg",  label: "Milligrams",  shortLabel: "mg",  unit: UnitMass.milligrams,  icon: "pills.fill",        accentColor: c),
                UnitEntry(id: "lb",  label: "Pounds",      shortLabel: "lb",  unit: UnitMass.pounds,      icon: "dumbbell.fill",     accentColor: c),
                UnitEntry(id: "oz",  label: "Ounces",      shortLabel: "oz",  unit: UnitMass.ounces,      icon: "circle.fill",       accentColor: c),
            ]
        case .volume:
            let c = Color(red: 0.35, green: 0.85, blue: 0.95)
            return [
                UnitEntry(id: "L",    label: "Liters",       shortLabel: "L",    unit: UnitVolume.liters,       icon: "waterbottle.fill",    accentColor: c),
                UnitEntry(id: "mL",   label: "Milliliters",  shortLabel: "mL",   unit: UnitVolume.milliliters,  icon: "drop.fill",           accentColor: c),
                UnitEntry(id: "m3",   label: "Cubic Meters", shortLabel: "m³",   unit: UnitVolume.cubicMeters,  icon: "cube.fill",           accentColor: c),
                UnitEntry(id: "gal",  label: "Gallons (US)", shortLabel: "gal",  unit: UnitVolume.gallons,      icon: "fuelpump.fill",       accentColor: c),
                UnitEntry(id: "floz", label: "Fl. Ounces",   shortLabel: "fl oz",unit: UnitVolume.fluidOunces,  icon: "cup.and.saucer.fill", accentColor: c),
                UnitEntry(id: "cup",  label: "Cups",         shortLabel: "cup",  unit: UnitVolume.cups,         icon: "cup.and.saucer",      accentColor: c),
            ]
        case .speed:
            let c = Color(red: 1.00, green: 0.82, blue: 0.28)
            return [
                UnitEntry(id: "kmh", label: "km/h",  shortLabel: "km/h", unit: UnitSpeed.kilometersPerHour, icon: "car.fill",      accentColor: c),
                UnitEntry(id: "ms",  label: "m/s",   shortLabel: "m/s",  unit: UnitSpeed.metersPerSecond,   icon: "wind",          accentColor: c),
                UnitEntry(id: "mph", label: "mph",   shortLabel: "mph",  unit: UnitSpeed.milesPerHour,      icon: "speedometer",   accentColor: c),
                UnitEntry(id: "kn",  label: "Knots", shortLabel: "kn",   unit: UnitSpeed.knots,             icon: "sailboat.fill", accentColor: c),
            ]
        }
    }
}

// MARK: - View

struct UnitConverterView: View {

    @State private var category: UnitCategory = .length
    @State private var texts: [String: String] = [:]
    @FocusState private var focusedId: String?
    @Environment(\.colorScheme) private var colorScheme

    private var units: [UnitEntry] { category.units }

    // MARK: Adaptive accent colors (bright in dark mode, deep/saturated in light)

    private func adaptedAccent(for cat: UnitCategory) -> Color {
        switch cat {
        case .length: return colorScheme == .dark ? Color(red: 0.35, green: 0.78, blue: 1.00)
                                                  : Color(red: 0.08, green: 0.42, blue: 0.88)
        case .weight: return colorScheme == .dark ? Color(red: 0.50, green: 0.92, blue: 0.45)
                                                  : Color(red: 0.12, green: 0.58, blue: 0.15)
        case .volume: return colorScheme == .dark ? Color(red: 0.35, green: 0.85, blue: 0.95)
                                                  : Color(red: 0.05, green: 0.48, blue: 0.80)
        case .speed:  return colorScheme == .dark ? Color(red: 1.00, green: 0.82, blue: 0.28)
                                                  : Color(red: 0.68, green: 0.46, blue: 0.00)
        }
    }

    // MARK: Helpers

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

    private func formatValue(_ value: Double) -> String {
        guard value != 0 else { return "" }
        let absVal = abs(value)
        if absVal >= 0.001 && absVal < 1_000_000_000 {
            return String(format: "%.8g", value)
        }
        return String(format: "%.4e", value)
    }

    private func textBinding(for id: String) -> Binding<String> {
        Binding(
            get: { texts[id] ?? "" },
            set: { texts[id] = $0 }
        )
    }

    // MARK: Calculation

    private func calculate(from sourceId: String) {
        let raw = numericOnly(texts[sourceId] ?? "")
        guard !raw.isEmpty, let value = Double(raw),
              let sourceEntry = units.first(where: { $0.id == sourceId })
        else {
            let others = units.filter { $0.id != sourceId }.map(\.id)
            withAnimation(.spring(response: 0.25)) {
                for id in others { texts[id] = "" }
            }
            return
        }

        let baseValue = sourceEntry.unit.converter.baseUnitValue(fromValue: value)
        withAnimation(.spring(response: 0.25)) {
            for entry in units where entry.id != sourceId {
                let converted = entry.unit.converter.value(fromBaseUnitValue: baseValue)
                texts[entry.id] = formatValue(converted)
            }
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            texts = [:]
        }
        focusedId = nil
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 16) {
                    GlassEffectContainer { headerCard }
                    categoryPicker
                    GlassEffectContainer { hintCard }
                    inputSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focusedId = nil }
        }
        .navigationTitle("Unit Converter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: category) { _, _ in
            texts = [:]
            focusedId = nil
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
                Color(red: 0.04, green: 0.10, blue: 0.38),
                Color(red: 0.06, green: 0.16, blue: 0.48),
                Color(red: 0.04, green: 0.12, blue: 0.42),
                Color(red: 0.06, green: 0.18, blue: 0.44),
                Color(red: 0.08, green: 0.26, blue: 0.54),
                Color(red: 0.04, green: 0.14, blue: 0.46),
                Color(red: 0.03, green: 0.09, blue: 0.32),
                Color(red: 0.05, green: 0.14, blue: 0.40),
                Color(red: 0.03, green: 0.10, blue: 0.35)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(adaptedAccent(for: category).opacity(0.20))
                    .frame(width: 52, height: 52)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [adaptedAccent(for: category), adaptedAccent(for: category).opacity(0.70)], startPoint: .top, endPoint: .bottom)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Unit Converter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Enter any value — the others update live.")
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                ForEach(UnitCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                            category = cat
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(cat.label)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(category == cat ? adaptedAccent(for: cat) : Color.primary.opacity(0.40))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            category == cat
                                ? RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.primary.opacity(0.14))
                                    .transition(.opacity)
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

    // MARK: - Hint Card

    private var hintCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(adaptedAccent(for: category).opacity(0.80))
            Text("Type in any field — all others update instantly.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.60))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 10) {
            ForEach(units) { entry in
                GlassEffectContainer {
                    inputRow(entry: entry)
                }
            }
        }
    }

    @ViewBuilder
    private func inputRow(entry: UnitEntry) -> some View {
        let binding = textBinding(for: entry.id)
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(adaptedAccent(for: category).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: entry.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(adaptedAccent(for: category))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(adaptedAccent(for: category).opacity(0.85))

                TextField("0", text: binding)
                    .keyboardType(.decimalPad)
                    .focused($focusedId, equals: entry.id)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(adaptedAccent(for: category))
                    .onChange(of: binding.wrappedValue) { _, newVal in
                        guard focusedId == entry.id else { return }
                        let filtered = numericOnly(newVal)
                        if filtered != newVal { binding.wrappedValue = filtered; return }
                        calculate(from: entry.id)
                    }
            }

            Text(entry.shortLabel)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.primary.opacity(0.55))
                .frame(minWidth: 32, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UnitConverterView()
    }
}
