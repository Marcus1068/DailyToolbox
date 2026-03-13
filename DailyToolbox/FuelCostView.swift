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
//  FuelCostView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Unit System

private enum FuelUnit: String, CaseIterable {
    case metric   = "l/100km"
    case imperial = "MPG"

    var localizedKey: LocalizedStringKey {
        LocalizedStringKey(self.rawValue)
    }
}

// MARK: - Result

private struct FuelResult {
    let fuelNeeded:   Double   // litres or gallons
    let totalCost:    Double
    let costPerUnit:  Double   // cost per km or per mile
    let unit: FuelUnit

    var fuelString: String {
        unit == .metric
            ? String(format: "%.2f L", fuelNeeded)
            : String(format: "%.2f gal", fuelNeeded)
    }
    var costPerUnitString: String {
        unit == .metric
            ? String(format: "%.3f /km", costPerUnit)
            : String(format: "%.3f /mi", costPerUnit)
    }
}

// MARK: - View

struct FuelCostView: View {

    @State private var fuelUnit: FuelUnit = .metric
    @State private var distanceText    = ""   // km or miles
    @State private var consumptionText = ""   // l/100km or mpg
    @State private var priceText       = ""   // price per litre or gallon

    @State private var result: FuelResult? = nil
    @FocusState private var focused: Int?
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(red: 0.35, green: 0.90, blue: 0.70)
                             : Color(red: 0.05, green: 0.58, blue: 0.38)
    }
    private var fuelColor: Color {
        colorScheme == .dark ? Color(red: 0.80, green: 1.00, blue: 0.65)
                             : Color(red: 0.15, green: 0.55, blue: 0.20)
    }
    private var costColor: Color {
        colorScheme == .dark ? Color(red: 0.55, green: 0.85, blue: 1.00)
                             : Color(red: 0.08, green: 0.45, blue: 0.80)
    }

    // Labels
    private var distanceLabel: LocalizedStringKey {
        fuelUnit == .metric ? "Distance (km)" : "Distance (miles)"
    }
    private var consumptionLabel: LocalizedStringKey {
        fuelUnit == .metric ? "Fuel Consumption (l/100km)" : "Fuel Efficiency (MPG)"
    }
    private var priceLabel: LocalizedStringKey {
        fuelUnit == .metric ? "Fuel Price (per litre)" : "Fuel Price (per gallon)"
    }
    private var distancePlaceholder: LocalizedStringKey {
        fuelUnit == .metric ? "500" : "300"
    }
    private var consumptionPlaceholder: LocalizedStringKey {
        fuelUnit == .metric ? "7.5" : "35"
    }

    // MARK: Calculation

    private func calculate() {
        let dist  = Double(distanceText.replacingOccurrences(of: ",", with: "."))    ?? 0
        let cons  = Double(consumptionText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let price = Double(priceText.replacingOccurrences(of: ",", with: "."))       ?? 0
        guard dist > 0, cons > 0, price > 0 else { result = nil; return }

        let fuelNeeded: Double
        let costPerUnit: Double

        if fuelUnit == .metric {
            fuelNeeded  = dist * cons / 100.0
            costPerUnit = fuelNeeded * price / dist
        } else {
            // mpg: gallons = miles / mpg
            fuelNeeded  = dist / cons
            costPerUnit = fuelNeeded * price / dist
        }

        let totalCost = fuelNeeded * price
        withAnimation(.spring(response: 0.3)) {
            result = FuelResult(fuelNeeded: fuelNeeded, totalCost: totalCost,
                                costPerUnit: costPerUnit, unit: fuelUnit)
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            distanceText = ""; consumptionText = ""; priceText = ""; result = nil
        }
        focused = nil
    }

    private func currency(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
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
        .navigationTitle("Fuel Cost")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: fuelUnit) { _, _ in calculate() }
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
                Color(red:0.03,green:0.16,blue:0.12), Color(red:0.04,green:0.20,blue:0.14), Color(red:0.03,green:0.16,blue:0.12),
                Color(red:0.04,green:0.20,blue:0.15), Color(red:0.05,green:0.26,blue:0.18), Color(red:0.04,green:0.20,blue:0.14),
                Color(red:0.02,green:0.14,blue:0.10), Color(red:0.03,green:0.18,blue:0.13), Color(red:0.02,green:0.14,blue:0.10)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [accent, accent.opacity(0.70)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "fuelpump.fill")
                    .font(.title2).foregroundStyle(Color.primary)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fuel & Trip Cost")
                    .font(.headline.weight(.bold)).foregroundStyle(Color.primary)
                Text("Distance · Consumption · Price")
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

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Trip Details")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accent)
                Spacer()
                // Unit toggle
                HStack(spacing: 0) {
                    ForEach(FuelUnit.allCases, id: \.self) { unit in
                        let sel = fuelUnit == unit
                        Button {
                            withAnimation(.spring(response: 0.25)) { fuelUnit = unit }
                        } label: {
                            Text(unit.localizedKey)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
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

            fuelField(label: distanceLabel, placeholder: distancePlaceholder,
                      text: $distanceText, focusTag: 1, icon: "road.lanes")
            fuelField(label: consumptionLabel, placeholder: consumptionPlaceholder,
                      text: $consumptionText, focusTag: 2, icon: "gauge.with.dots.needle.33percent")
            fuelField(label: priceLabel, placeholder: "1.80",
                      text: $priceText, focusTag: 3, icon: "tag.fill")

            Button(action: calculate) {
                Text("Calculate")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(accent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func fuelField(label: LocalizedStringKey, placeholder: LocalizedStringKey,
                           text: Binding<String>, focusTag: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent.opacity(0.80))
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.70))
                    .frame(width: 20)
                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: focusTag)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(accent)
                    .onChange(of: text.wrappedValue) { _, _ in
                        guard focused == focusTag else { return }
                        calculate()
                    }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.07)))
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private func resultCard(_ res: FuelResult) -> some View {
        VStack(spacing: 0) {
            // Hero: total cost
            VStack(spacing: 6) {
                Text("Total Trip Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.60))
                Text(currency(res.totalCost))
                    .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            Divider().overlay(Color.primary.opacity(0.10))

            HStack(spacing: 0) {
                resultCell(label: "Fuel Needed", value: res.fuelString,
                           color: fuelColor)
                Divider().frame(height: 50).overlay(Color.primary.opacity(0.10))
                resultCell(label: "Cost per Unit", value: res.costPerUnitString,
                           color: costColor)
            }
            .padding(.vertical, 14)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func resultCell(label: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.55))
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FuelCostView()
    }
}
