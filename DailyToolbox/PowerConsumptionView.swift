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
//  PowerConsumptionView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Device Presets

private struct DevicePreset: Identifiable {
    let id   = UUID()
    let emoji: String
    let name:  String
    let watts: Double

    static let all: [DevicePreset] = [
        DevicePreset(emoji: "💡", name: "LED",     watts: 10),
        DevicePreset(emoji: "💡", name: "Bulb",    watts: 60),
        DevicePreset(emoji: "📺", name: "TV",      watts: 120),
        DevicePreset(emoji: "🖥",  name: "PC",      watts: 200),
        DevicePreset(emoji: "❄️", name: "Fridge",  watts: 150),
        DevicePreset(emoji: "🔥", name: "Heater",  watts: 1500),
        DevicePreset(emoji: "🍳", name: "Oven",    watts: 2200),
        DevicePreset(emoji: "🫧", name: "Washer",  watts: 500),
        DevicePreset(emoji: "🌡️", name: "A/C",     watts: 1200),
        DevicePreset(emoji: "🔌", name: "Charger", watts: 20),
    ]
}

// MARK: - Result Row

private struct CostResultRow: View {
    let icon:    String
    let period:  LocalizedStringKey
    let kwh:     Double
    let cost:    Double
    let accent:  Color
    let large:   Bool

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent.opacity(0.75))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(period)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent.opacity(0.85))
                Text(String(format: "%.3f kWh", kwh))
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.32))
            }

            Spacer()

            Text(cost.formatted(.number.precision(.fractionLength(large ? 2 : 3))) + " €")
                .font(.system(size: large ? 28 : 18,
                              weight: .black,
                              design: .rounded).monospacedDigit())
                .foregroundStyle(
                    large
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.20),
                                     Color(red: 1.0, green: 0.60, blue: 0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.primary.opacity(0.80))
                )
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35), value: cost)
        }
    }
}

// MARK: - Main View

struct PowerConsumptionView: View {

    @State private var costText:  String = ""
    @State private var hoursText: String = ""
    @State private var wattText:  String = ""
    @FocusState private var focused: Field?

    private enum Field: Hashable { case cost, hours, watt }

    // MARK: Helpers

    private func s(_ t: String) -> String { t.replacingOccurrences(of: ",", with: ".") }

    private var cost:  Double? { Double(s(costText))  }
    private var hours: Double? { Double(s(hoursText)) }
    private var watt:  Double? { Double(s(wattText))  }

    // MARK: Results

    private var results: (daily: Double, monthly: Double, yearly: Double,
                          dailyKwh: Double, monthlyKwh: Double, yearlyKwh: Double)? {
        guard let w = watt, let h = hours, let c = cost,
              w >= 0, h >= 0, h <= 24, c >= 0 else { return nil }
        let pc = PowerConsumption(watt: w, hours: h, cost: c)
        let dKwh = w * h / 1000.0
        return (pc.computeDailyCost,
                pc.computeMonthlyCost,
                pc.computeYearlyCost,
                dKwh,
                dKwh * 30,
                dKwh * 365)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        inputSection
                        devicePresetsRow
                        if let r = results {
                            resultsCard(r)
                        } else {
                            resultsPlaceholder
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .onTapGesture { focused = nil }
        }
        .navigationTitle("Power Consumption")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if let saved = NSUbiquitousKeyValueStore.default.string(forKey: Global.keyCostWatt),
               !saved.isEmpty {
                costText = saved
            }
        }
        .onDisappear {
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    // MARK: Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.13, green: 0.08, blue: 0.02),
                Color(red: 0.19, green: 0.11, blue: 0.02),
                Color(red: 0.11, green: 0.07, blue: 0.01),
                Color(red: 0.16, green: 0.10, blue: 0.02),
                Color(red: 0.24, green: 0.15, blue: 0.03),
                Color(red: 0.13, green: 0.08, blue: 0.02),
                Color(red: 0.09, green: 0.05, blue: 0.01),
                Color(red: 0.15, green: 0.09, blue: 0.02),
                Color(red: 0.10, green: 0.06, blue: 0.01)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.10).opacity(0.14))
                    .frame(width: 50, height: 50)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.90, blue: 0.20),
                                     Color(red: 1.0, green: 0.55, blue: 0.10)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Power Cost Calculator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Enter wattage, hours/day and price per kWh")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            inputCard(
                field: .cost,
                icon: "eurosign.circle.fill",
                label: "Cost per kWh",
                hint:  "e.g. 0.30 for 30 ct/kWh",
                placeholder: "0.30",
                text: $costText,
                accent: Color(red: 1.00, green: 0.88, blue: 0.20),
                unit: "€/kWh",
                onChange: {
                    NSUbiquitousKeyValueStore.default.set(s(costText), forKey: Global.keyCostWatt)
                }
            )

            inputCard(
                field: .hours,
                icon: "clock.fill",
                label: "Daily Usage",
                hint:  "Hours per day (0 – 24)",
                placeholder: "8",
                text: $hoursText,
                accent: Color(red: 1.00, green: 0.60, blue: 0.15),
                unit: "h/day",
                stepDelta: 1,
                stepRange: 0...24
            )

            inputCard(
                field: .watt,
                icon: "bolt.circle.fill",
                label: "Device Power",
                hint:  "Watt consumption of the device",
                placeholder: "100",
                text: $wattText,
                accent: Color(red: 1.00, green: 0.45, blue: 0.10),
                unit: "W"
            )
        }
    }

    @ViewBuilder
    private func inputCard(
        field: Field,
        icon: String,
        label: LocalizedStringKey,
        hint: LocalizedStringKey,
        placeholder: String,
        text: Binding<String>,
        accent: Color,
        unit: LocalizedStringKey,
        stepDelta: Double? = nil,
        stepRange: ClosedRange<Double>? = nil,
        onChange: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent.opacity(0.88))
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.32))
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    TextField(placeholder, text: text)
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: field)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                        .tint(accent)
                        .onChange(of: text.wrappedValue) { _, new in
                            let clean = new.replacingOccurrences(of: ",", with: ".")
                            if clean != new { text.wrappedValue = clean }
                            onChange?()
                        }
                    Text(unit)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.38))
                }
            }

            Spacer(minLength: 0)

            if let delta = stepDelta, let range = stepRange {
                VStack(spacing: 6) {
                    Button {
                        let v = min(range.upperBound,
                                    (Double(s(text.wrappedValue)) ?? 0) + delta)
                        text.wrappedValue = v.formatted(.number.precision(.fractionLength(0)))
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.glass)

                    Button {
                        let v = max(range.lowerBound,
                                    (Double(s(text.wrappedValue)) ?? 0) - delta)
                        text.wrappedValue = v.formatted(.number.precision(.fractionLength(0)))
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.glass)
                }
            } else if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.primary.opacity(0.28))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Device Presets

    private var devicePresetsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "square.grid.2x2")
                    .font(.caption2.weight(.semibold))
                Text("Quick Presets")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.48))
            .padding(.leading, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DevicePreset.all) { preset in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                wattText = preset.watts
                                    .formatted(.number.precision(.fractionLength(0)))
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(preset.emoji).font(.caption)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(LocalizedStringKey(preset.name))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    Text("\(Int(preset.watts))W")
                                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                                        .foregroundStyle(Color.primary.opacity(0.45))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: Results

    @ViewBuilder
    private func resultsCard(
        _ r: (daily: Double, monthly: Double, yearly: Double,
              dailyKwh: Double, monthlyKwh: Double, yearlyKwh: Double)
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption.weight(.semibold))
                Text("Cost Overview")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)

            VStack(spacing: 10) {
                CostResultRow(
                    icon:   "sunrise",
                    period: "Per Day",
                    kwh:    r.dailyKwh,
                    cost:   r.daily,
                    accent: Color(red: 0.85, green: 0.78, blue: 0.25),
                    large:  false
                )

                Divider().overlay(Color.primary.opacity(0.08))

                CostResultRow(
                    icon:   "calendar",
                    period: "Per Month",
                    kwh:    r.monthlyKwh,
                    cost:   r.monthly,
                    accent: Color(red: 1.00, green: 0.70, blue: 0.18),
                    large:  false
                )

                Divider().overlay(Color.primary.opacity(0.08))

                CostResultRow(
                    icon:   "calendar.badge.clock",
                    period: "Per Year",
                    kwh:    r.yearlyKwh,
                    cost:   r.yearly,
                    accent: Color(red: 1.00, green: 0.88, blue: 0.20),
                    large:  true
                )
            }

            // Energy bar (daily : monthly : yearly proportional)
            Divider().overlay(Color.primary.opacity(0.08)).padding(.top, 12)
            energyBar(r)
                .padding(.top, 10)
        }
        .padding(18)
        .glassEffect(
            .regular.tint(Color(red: 0.14, green: 0.09, blue: 0.01)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: r.yearly)
    }

    private func energyBar(
        _ r: (daily: Double, monthly: Double, yearly: Double,
              dailyKwh: Double, monthlyKwh: Double, yearlyKwh: Double)
    ) -> some View {
        GeometryReader { geo in
            let maxKwh = r.yearlyKwh
            let dFrac  = maxKwh > 0 ? r.dailyKwh   / maxKwh : 0
            let mFrac  = maxKwh > 0 ? r.monthlyKwh  / maxKwh : 0
            let w      = geo.size.width

            VStack(spacing: 5) {
                barRow(label: "Day", frac: dFrac, w: w,
                       color: Color(red: 0.85, green: 0.78, blue: 0.25))
                barRow(label: "Month", frac: mFrac, w: w,
                       color: Color(red: 1.00, green: 0.70, blue: 0.18))
                barRow(label: "Year", frac: 1.0, w: w,
                       color: Color(red: 1.00, green: 0.88, blue: 0.20))
            }
        }
        .frame(height: 60)
    }

    private func barRow(label: LocalizedStringKey, frac: Double, w: CGFloat, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.40))
                .frame(width: 34, alignment: .trailing)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [color.opacity(0.60), color],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(6, (w - 42) * frac), height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: frac)
            }
        }
    }

    private var resultsPlaceholder: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.22))
            Text("Fill in all three fields to see your power costs")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.35))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PowerConsumptionView()
    }
}
