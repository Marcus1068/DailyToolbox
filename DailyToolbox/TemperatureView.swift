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
//  TemperatureView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

// MARK: - Field identity

private enum TempField: CaseIterable {
    case celsius, fahrenheit, kelvin

    var label: LocalizedStringKey {
        switch self {
        case .celsius:    return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        case .kelvin:     return "Kelvin"
        }
    }

    var unit: String {
        switch self {
        case .celsius:    return "°C"
        case .fahrenheit: return "°F"
        case .kelvin:     return "K"
        }
    }

    var icon: String {
        switch self {
        case .celsius:    return "thermometer.medium"
        case .fahrenheit: return "thermometer.high"
        case .kelvin:     return "atom"
        }
    }

    var accentColor: Color {
        switch self {
        case .celsius:    return Color(red: 1.00, green: 0.65, blue: 0.30)
        case .fahrenheit: return Color(red: 1.00, green: 0.82, blue: 0.40)
        case .kelvin:     return Color(red: 0.90, green: 0.55, blue: 0.25)
        }
    }

    /// Whether this scale allows negative input
    var allowsNegative: Bool { self != .kelvin }
}

// MARK: - Temperature Gauge

private struct TemperatureGaugeView: View {
    let celsius: Double?

    private let gaugeMin: Double = -60
    private let gaugeMax: Double = 160

    private var progress: Double {
        guard let c = celsius else { return 0.35 }
        return max(0, min(1, (c - gaugeMin) / (gaugeMax - gaugeMin)))
    }

    private let ticks: [(value: Double, label: String)] = [
        (-60, "-60"), (0, "0°"), (37, "37°"), (100, "100°"), (160, "160")
    ]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.30, blue: 0.95),
                                    Color(red: 0.00, green: 0.75, blue: 0.90),
                                    Color(red: 0.10, green: 0.85, blue: 0.45),
                                    Color(red: 0.95, green: 0.90, blue: 0.10),
                                    Color(red: 1.00, green: 0.55, blue: 0.05),
                                    Color(red: 0.90, green: 0.12, blue: 0.05),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 18)
                        .offset(y: 6)

                    // Tick marks
                    ForEach(ticks, id: \.value) { tick in
                        let pos = max(0, min(1, (tick.value - gaugeMin) / (gaugeMax - gaugeMin)))
                        Rectangle()
                            .fill(Color.primary.opacity(0.40))
                            .frame(width: 1.5, height: 10)
                            .offset(x: pos * (geo.size.width - 2), y: 10)
                    }

                    // Indicator circle
                    ZStack {
                        Circle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                        Circle()
                            .fill(markerColor)
                            .padding(4)
                    }
                    .frame(width: 28, height: 28)
                    .offset(x: max(0, min(
                        geo.size.width - 28,
                        progress * geo.size.width - 14
                    )))
                    .animation(.spring(response: 0.4, dampingFraction: 0.72), value: progress)
                }
            }
            .frame(height: 30)

            // Tick labels
            GeometryReader { geo in
                ForEach(ticks, id: \.value) { tick in
                    let pos = max(0, min(1, (tick.value - gaugeMin) / (gaugeMax - gaugeMin)))
                    Text(tick.label)
                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                        .foregroundStyle(Color.primary.opacity(0.55))
                        .position(x: pos * geo.size.width, y: 6)
                }
            }
            .frame(height: 14)
        }
    }

    private var markerColor: Color {
        guard let c = celsius else { return Color(red: 0.5, green: 0.7, blue: 1.0) }
        switch c {
        case ..<0:    return Color(red: 0.15, green: 0.40, blue: 0.95)
        case 0..<18:  return Color(red: 0.10, green: 0.75, blue: 0.85)
        case 18..<26: return Color(red: 0.20, green: 0.85, blue: 0.40)
        case 26..<37: return Color(red: 0.95, green: 0.80, blue: 0.10)
        case 37..<60: return Color(red: 1.00, green: 0.50, blue: 0.05)
        default:      return Color(red: 0.90, green: 0.10, blue: 0.05)
        }
    }
}

// MARK: - Main View

struct TemperatureView: View {

    @State private var celsiusText:    String = ""
    @State private var fahrenheitText: String = ""
    @State private var kelvinText:     String = ""
    @FocusState private var focused: TempField?

    // MARK: Helpers

    private var celsiusValue: Double? { Double(celsiusText) }

    /// Allow digits, at most one decimal point, and an optional leading minus.
    /// Replaces comma with dot (handles European keyboards).
    private func numericOnly(_ s: String, allowNegative: Bool = false) -> String {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        let isNeg = allowNegative && normalized.hasPrefix("-")
        var dotSeen = false
        let digits = String(normalized.filter { c in
            if c == "." {
                guard !dotSeen else { return false }
                dotSeen = true; return true
            }
            return c.isNumber
        })
        return (isNeg ? "-" : "") + digits
    }

    private func toggleSign(_ text: String) -> String {
        text.hasPrefix("-") ? String(text.dropFirst()) : "-" + text
    }

    // MARK: - Calculation

    private func calculate(changed: TempField) {
        switch changed {
        case .celsius:
            guard let c = Double(numericOnly(celsiusText, allowNegative: true)) else {
                fahrenheitText = ""; kelvinText = ""; return
            }
            let t = Temperature(celsius: c)
            withAnimation(.spring(response: 0.3)) {
                fahrenheitText = t.fahrenheitToString
                kelvinText     = t.kelvinToString
            }
        case .fahrenheit:
            guard let f = Double(numericOnly(fahrenheitText, allowNegative: true)) else {
                celsiusText = ""; kelvinText = ""; return
            }
            let t = Temperature(fahrenheit: f)
            withAnimation(.spring(response: 0.3)) {
                celsiusText = t.celsiusToString
                kelvinText  = t.kelvinToString
            }
        case .kelvin:
            guard let k = Double(numericOnly(kelvinText)), k >= 0 else {
                celsiusText = ""; fahrenheitText = ""; return
            }
            let t = Temperature(kelvin: k)
            withAnimation(.spring(response: 0.3)) {
                celsiusText    = t.celsiusToString
                fahrenheitText = t.fahrenheitToString
            }
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            celsiusText = ""; fahrenheitText = ""; kelvinText = ""
        }
    }

    // MARK: Classification

    private typealias TempClass = (label: LocalizedStringKey, emoji: String, color: Color)

    private var classification: TempClass? {
        guard let c = celsiusValue else { return nil }
        switch c {
        case ..<(-20):  return ("Extreme Cold", "🧊", Color(red: 0.15, green: 0.35, blue: 0.95))
        case (-20)..<0: return ("Freezing", "❄️", Color(red: 0.25, green: 0.60, blue: 0.95))
        case 0..<10:    return ("Cold", "🌨", Color(red: 0.15, green: 0.70, blue: 0.85))
        case 10..<18:   return ("Cool", "🌤", Color(red: 0.15, green: 0.80, blue: 0.55))
        case 18..<26:   return ("Comfortable", "☀️", Color(red: 0.90, green: 0.78, blue: 0.15))
        case 26..<37:   return ("Warm", "🌡️", Color(red: 1.00, green: 0.55, blue: 0.10))
        case 37..<60:   return ("Hot", "🔥", Color(red: 0.95, green: 0.28, blue: 0.08))
        default:        return ("Extreme Heat", "♨️", Color(red: 0.85, green: 0.08, blue: 0.05))
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            // No single outer GlassEffectContainer — each card manages its own
            // glass scope so that interactive overlays (± button) are genuinely
            // above the glass compositing layer in the render tree.
            ScrollView {
                VStack(spacing: 20) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { gaugeCard }
                    inputSection
                    if let cls = classification {
                        GlassEffectContainer { classificationBadge(cls) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .onTapGesture { focused = nil }
        }
        .navigationTitle("Temperature")
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
                Color(red: 0.52, green: 0.12, blue: 0.03),
                Color(red: 0.60, green: 0.22, blue: 0.03),
                Color(red: 0.44, green: 0.07, blue: 0.05),
                Color(red: 0.56, green: 0.18, blue: 0.02),
                Color(red: 0.66, green: 0.30, blue: 0.03),
                Color(red: 0.48, green: 0.10, blue: 0.07),
                Color(red: 0.42, green: 0.09, blue: 0.03),
                Color(red: 0.56, green: 0.20, blue: 0.02),
                Color(red: 0.46, green: 0.09, blue: 0.05)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.65, blue: 0.3).opacity(0.20))
                    .frame(width: 52, height: 52)
                Image(systemName: "thermometer.sun.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.82, blue: 0.4),
                                     Color(red: 1.0, green: 0.50, blue: 0.15)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Temperature Conversion")
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

    // MARK: - Gauge

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Temperature Scale",
                      systemImage: "gauge.open.with.lines.needle.33percent")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.70))
                Spacer()
                if let c = celsiusValue {
                    Text(c.formatted(.number.precision(.fractionLength(1))) + " °C")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.4))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: celsiusValue)
                }
            }
            TemperatureGaugeView(celsius: celsiusValue)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            cardRow(field: .celsius,    text: $celsiusText)
            cardRow(field: .fahrenheit, text: $fahrenheitText)
            cardRow(field: .kelvin,     text: $kelvinText)
        }
    }

    // The ± button and unit badge live in a ZStack ABOVE the GlassEffectContainer
    // so they are outside the glass compositing context and fully hittable.
    @ViewBuilder
    private func cardRow(field: TempField, text: Binding<String>) -> some View {
        ZStack(alignment: .trailing) {
            GlassEffectContainer {
                inputCard(field: field, text: text)
            }
            HStack(spacing: 10) {
                if field.allowsNegative {
                    Button {
                        guard !text.wrappedValue.isEmpty else { return }
                        text.wrappedValue = toggleSign(text.wrappedValue)
                        calculate(changed: field)
                    } label: {
                        Text("±")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(text.wrappedValue.isEmpty
                                ? Color.primary.opacity(0.35)
                                : field.accentColor)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.30))
                                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(text.wrappedValue.isEmpty)
                }
                Text(field.unit)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.60))
                    .frame(minWidth: 24, alignment: .trailing)
            }
            .padding(.trailing, 16)
        }
    }

    @ViewBuilder
    private func inputCard(field: TempField, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(field.accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: field.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(field.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(field.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(field.accentColor.opacity(0.85))

                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: field)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(field.accentColor)
                    .onChange(of: text.wrappedValue) { _, newVal in
                        // Ignore programmatic updates from calculate() — only
                        // process keystrokes from the field the user is typing in.
                        guard focused == field else { return }
                        let filtered = numericOnly(newVal, allowNegative: field.allowsNegative)
                        if filtered != newVal { text.wrappedValue = filtered; return }
                        calculate(changed: field)
                    }
            }

            // Reserve space for the trailing ± button + unit badge overlay
            Color.clear.frame(width: field.allowsNegative ? 80 : 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Classification Badge

    @ViewBuilder
    private func classificationBadge(_ cls: TempClass) -> some View {
        HStack(spacing: 12) {
            Text(cls.emoji)
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(cls.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.primary)
                if let c = celsiusValue {
                    let cStr = c.formatted(.number.precision(.fractionLength(1)))
                    let fStr = (Double(fahrenheitText) ?? 0).formatted(.number.precision(.fractionLength(1)))
                    let kStr = (Double(kelvinText) ?? 0).formatted(.number.precision(.fractionLength(1)))
                    Text("\(cStr) °C · \(fStr) °F · \(kStr) K")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.primary.opacity(0.65))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(
            .regular.tint(cls.color.opacity(0.4)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: cls.label)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TemperatureView()
    }
}
