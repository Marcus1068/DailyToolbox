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
//  WindChillView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Comfort Level

enum ComfortLevel: CaseIterable {
    case frostbiteDanger, veryCold, cold, cool, comfortable, warm, hot, veryHot, heatStrokeDanger

    static func from(feelsLikeCelsius t: Double) -> ComfortLevel {
        switch t {
        case ..<(-27):  return .frostbiteDanger
        case ..<(-10):  return .veryCold
        case ..<0:      return .cold
        case ..<10:     return .cool
        case ..<20:     return .comfortable
        case ..<28:     return .warm
        case ..<35:     return .hot
        case ..<41:     return .veryHot
        default:        return .heatStrokeDanger
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .frostbiteDanger:  return "Frostbite Danger"
        case .veryCold:         return "Very Cold"
        case .cold:             return "Cold"
        case .cool:             return "Cool"
        case .comfortable:      return "Comfortable"
        case .warm:             return "Warm"
        case .hot:              return "Hot"
        case .veryHot:          return "Very Hot"
        case .heatStrokeDanger: return "Heat Stroke Danger"
        }
    }

    var emoji: String {
        switch self {
        case .frostbiteDanger:  return "🧊"
        case .veryCold:         return "🥶"
        case .cold:             return "❄️"
        case .cool:             return "🌬️"
        case .comfortable:      return "😊"
        case .warm:             return "☀️"
        case .hot:              return "🌡️"
        case .veryHot:          return "🔥"
        case .heatStrokeDanger: return "🥵"
        }
    }

    var color: Color {
        switch self {
        case .frostbiteDanger:  return Color(red: 0.55, green: 0.85, blue: 1.00)
        case .veryCold:         return Color(red: 0.30, green: 0.65, blue: 1.00)
        case .cold:             return Color(red: 0.20, green: 0.52, blue: 0.95)
        case .cool:             return Color(red: 0.35, green: 0.72, blue: 0.88)
        case .comfortable:      return Color(red: 0.25, green: 0.82, blue: 0.50)
        case .warm:             return Color(red: 1.00, green: 0.82, blue: 0.20)
        case .hot:              return Color(red: 1.00, green: 0.55, blue: 0.10)
        case .veryHot:          return Color(red: 1.00, green: 0.28, blue: 0.08)
        case .heatStrokeDanger: return Color(red: 0.90, green: 0.10, blue: 0.05)
        }
    }

    /// Background gradient colors (2×2 MeshGradient)
    var backgroundColors: [Color] {
        switch self {
        case .frostbiteDanger:
            return [Color(red:0.55,green:0.88,blue:1.00), Color(red:0.70,green:0.94,blue:1.00),
                    Color(red:0.40,green:0.80,blue:0.98), Color(red:0.60,green:0.90,blue:1.00)]
        case .veryCold:
            return [Color(red:0.10,green:0.25,blue:0.65), Color(red:0.15,green:0.40,blue:0.80),
                    Color(red:0.08,green:0.20,blue:0.55), Color(red:0.14,green:0.35,blue:0.72)]
        case .cold:
            return [Color(red:0.12,green:0.30,blue:0.70), Color(red:0.20,green:0.50,blue:0.90),
                    Color(red:0.10,green:0.25,blue:0.60), Color(red:0.18,green:0.45,blue:0.82)]
        case .cool:
            return [Color(red:0.15,green:0.45,blue:0.80), Color(red:0.28,green:0.62,blue:0.92),
                    Color(red:0.12,green:0.38,blue:0.72), Color(red:0.22,green:0.55,blue:0.85)]
        case .comfortable:
            return [Color(red:0.10,green:0.50,blue:0.30), Color(red:0.18,green:0.68,blue:0.45),
                    Color(red:0.08,green:0.42,blue:0.25), Color(red:0.15,green:0.60,blue:0.38)]
        case .warm:
            return [Color(red:0.85,green:0.55,blue:0.05), Color(red:0.95,green:0.72,blue:0.15),
                    Color(red:0.75,green:0.45,blue:0.02), Color(red:0.88,green:0.62,blue:0.10)]
        case .hot:
            return [Color(red:0.80,green:0.28,blue:0.05), Color(red:0.95,green:0.45,blue:0.10),
                    Color(red:0.70,green:0.20,blue:0.02), Color(red:0.88,green:0.38,blue:0.08)]
        case .veryHot:
            return [Color(red:0.72,green:0.12,blue:0.02), Color(red:0.90,green:0.25,blue:0.05),
                    Color(red:0.62,green:0.08,blue:0.01), Color(red:0.80,green:0.18,blue:0.03)]
        case .heatStrokeDanger:
            return [Color(red:0.60,green:0.06,blue:0.01), Color(red:0.80,green:0.10,blue:0.02),
                    Color(red:0.50,green:0.04,blue:0.01), Color(red:0.72,green:0.08,blue:0.02)]
        }
    }
}

// MARK: - Calculator

struct WindChillCalculator {

    // NOAA Wind Chill formula: valid when T_c <= 10°C and wind >= 4.8 km/h
    static func windChill(tempC: Double, windKmh: Double) -> Double? {
        guard tempC <= 10, windKmh >= 4.8 else { return nil }
        let v = pow(windKmh, 0.16)
        return 13.12 + 0.6215 * tempC - 11.37 * v + 0.3965 * tempC * v
    }

    // Rothfusz Heat Index: valid when T_c >= 27°C and RH >= 40%
    static func heatIndex(tempC: Double, humidity: Double) -> Double? {
        guard tempC >= 27, humidity >= 40 else { return nil }
        let T = tempC, RH = humidity
        return -8.78469475556
             +  1.61139411  * T
             +  2.33854883889 * RH
             -  0.14611605  * T  * RH
             -  0.012308094 * T  * T
             -  0.016424828 * RH * RH
             +  0.002211732 * T  * RH * RH
             +  0.00072546  * T  * T  * RH
             -  0.000003582 * T  * T  * RH * RH
    }

    static func feelsLike(tempC: Double, windKmh: Double, humidity: Double) -> Double {
        if let wc = windChill(tempC: tempC, windKmh: windKmh) { return wc }
        if let hi = heatIndex(tempC: tempC, humidity: humidity) { return hi }
        return tempC   // within comfortable range — feels same as air temp
    }
}

// MARK: - Main View

struct WindChillView: View {

    @AppStorage("windChill.useFahrenheit") private var useFahrenheit: Bool  = false
    @AppStorage("windChill.useMph")        private var useMph:        Bool  = false
    @AppStorage("windChill.tempC")         private var storedTempC:   Double = 5.0
    @AppStorage("windChill.windKmh")       private var storedWindKmh: Double = 20.0
    @AppStorage("windChill.humidity")      private var humidity:      Double = 60.0

    @Environment(\.colorScheme) private var colorScheme

    // MARK: Display helpers

    private var tempDisplay: Double {
        get { useFahrenheit ? storedTempC * 9/5 + 32 : storedTempC }
    }
    private var windDisplay: Double {
        get { useMph ? storedWindKmh / 1.60934 : storedWindKmh }
    }

    private var feelsLikeC: Double {
        WindChillCalculator.feelsLike(tempC: storedTempC, windKmh: storedWindKmh, humidity: humidity)
    }
    private var feelsLikeDisplay: Double {
        useFahrenheit ? feelsLikeC * 9/5 + 32 : feelsLikeC
    }

    private var comfort: ComfortLevel { ComfortLevel.from(feelsLikeCelsius: feelsLikeC) }

    private var mode: LocalizedStringKey {
        if WindChillCalculator.windChill(tempC: storedTempC, windKmh: storedWindKmh) != nil {
            return "Wind Chill"
        }
        if WindChillCalculator.heatIndex(tempC: storedTempC, humidity: humidity) != nil {
            return "Heat Index"
        }
        return "Apparent Temperature"
    }

    private var tempUnit:  String { useFahrenheit ? "°F" : "°C" }
    private var speedUnit: String { useMph ? "mph" : "km/h" }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        unitsRow
                        feelsLikeCard
                        comfortCard
                        inputsCard
                        formulaCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("Wind Chill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Background

    private var background: some View {
        MeshGradient(
            width: 2, height: 2,
            points: [[0,0],[1,0],[0,1],[1,1]],
            colors: comfort.backgroundColors
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: comfort.label)
    }

    // MARK: Units Row

    private var unitsRow: some View {
        HStack(spacing: 12) {
            Picker("Temperature", selection: $useFahrenheit) {
                Text("°C").tag(false)
                Text("°F").tag(true)
            }
            .pickerStyle(.segmented)

            Picker("Speed", selection: $useMph) {
                Text("km/h").tag(false)
                Text("mph").tag(true)
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Feels-Like Card

    private var feelsLikeCard: some View {
        VStack(spacing: 6) {
            Text(mode)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.70))
                .textCase(.uppercase)
                .kerning(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(feelsLikeDisplay, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText())
                Text(tempUnit)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .padding(.bottom, 8)
            }

            HStack(spacing: 6) {
                Text("Air temp:")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.55))
                Text("\(tempDisplay, format: .number.precision(.fractionLength(1)))\(tempUnit)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.80))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Comfort Card

    private var comfortCard: some View {
        HStack(spacing: 14) {
            Text(comfort.emoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 3) {
                Text(comfort.label)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(comfortDescription)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(
            .regular.tint(comfort.color.opacity(colorScheme == .dark ? 0.18 : 0.10)),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private var comfortDescription: LocalizedStringKey {
        switch comfort {
        case .frostbiteDanger:  return "Exposed skin can freeze in under 30 minutes"
        case .veryCold:         return "Dress in warm layers, limit time outdoors"
        case .cold:             return "Warm clothing required"
        case .cool:             return "Light jacket recommended"
        case .comfortable:      return "Pleasant conditions for outdoor activity"
        case .warm:             return "Light clothing, stay hydrated"
        case .hot:              return "Drink water regularly, seek shade"
        case .veryHot:          return "Limit strenuous activity, risk of heat exhaustion"
        case .heatStrokeDanger: return "Dangerous — stay indoors in air conditioning"
        }
    }

    // MARK: Inputs Card

    private var inputsCard: some View {
        VStack(spacing: 0) {

            // Temperature
            inputRow(
                icon:   "thermometer.medium",
                label:  "Air Temperature",
                value:  tempDisplay,
                unit:   tempUnit,
                step:   useFahrenheit ? 1.0 : 1.0,
                minVal: useFahrenheit ? -58 : -50,
                maxVal: useFahrenheit ?  122 :  50,
            ) { delta in
                let stepC = useFahrenheit ? delta * 5/9 : delta
                storedTempC = (storedTempC + stepC).clamped(to: -50...50)
            }

            Divider().padding(.horizontal, 16)

            // Wind speed
            inputRow(
                icon:   "wind",
                label:  "Wind Speed",
                value:  windDisplay,
                unit:   speedUnit,
                step:   useMph ? 1.0 : 1.0,
                minVal: 0,
                maxVal: useMph ? 125 : 200,
            ) { delta in
                let stepKmh = useMph ? delta * 1.60934 : delta
                storedWindKmh = max(0, storedWindKmh + stepKmh)
            }

            Divider().padding(.horizontal, 16)

            // Humidity
            inputRow(
                icon:   "humidity.fill",
                label:  "Humidity",
                value:  humidity,
                unit:   "%",
                step:   5.0,
                minVal: 0,
                maxVal: 100,
            ) { delta in
                humidity = (humidity + delta).clamped(to: 0...100)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private func inputRow(icon: String, label: LocalizedStringKey, value: Double,
                          unit: String, step: Double, minVal: Double, maxVal: Double,
                          precision: Int = 0, onChange: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.60))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.50))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value, format: .number.precision(.fractionLength(precision)))
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.55))
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(duration: 0.2)) { onChange(-step) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
                .buttonStyle(.plain)
                .disabled(value <= minVal)

                Button {
                    withAnimation(.spring(duration: 0.2)) { onChange(step) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
                .buttonStyle(.plain)
                .disabled(value >= maxVal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Formula Card

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
                Text("Formula")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }

            if WindChillCalculator.windChill(tempC: storedTempC, windKmh: storedWindKmh) != nil {
                Text("NOAA Wind Chill (T ≤ 10°C, wind ≥ 4.8 km/h)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.45))
                Text("WC = 13.12 + 0.6215·T − 11.37·V⁰·¹⁶ + 0.3965·T·V⁰·¹⁶")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.primary.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            } else if WindChillCalculator.heatIndex(tempC: storedTempC, humidity: humidity) != nil {
                Text("Rothfusz Heat Index (T ≥ 27°C, RH ≥ 40%)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.45))
                Text("HI = −8.78 + 1.61·T + 2.34·RH − 0.15·T·RH − …")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.primary.opacity(0.65))
            } else {
                Text("No significant wind chill or heat index effect at these conditions. Feels-like equals air temperature.")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.50))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Comparable clamping helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WindChillView()
    }
}
