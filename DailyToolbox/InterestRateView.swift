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
//  InterestRateView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

// MARK: - Circular Rate Gauge

private struct RateGaugeView: View {
    let rate: Double
    @Environment(\.colorScheme) private var colorScheme

    private var clampedRate: Double { max(0, min(100, rate) ) }
    private var progress: Double    { clampedRate / 100 }

    private var gaugeGold:  Color { colorScheme == .dark ? Color(red: 1.00, green: 0.82, blue: 0.22) : Color(red: 0.68, green: 0.48, blue: 0.00) }
    private var gaugeGreen: Color { colorScheme == .dark ? Color(red: 0.28, green: 0.95, blue: 0.58) : Color(red: 0.05, green: 0.58, blue: 0.28) }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 16)

            // Filled arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [gaugeGreen, gaugeGold, gaugeGold],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: progress)
                .shadow(color: gaugeGold.opacity(0.45), radius: 8, x: 0, y: 0)

            // Centre label
            VStack(spacing: 1) {
                Text(clampedRate.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: clampedRate)
                Text("%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Field identity

private enum InterestField: CaseIterable {
    case interest, capital, rate

    var label: LocalizedStringKey {
        switch self {
        case .interest: return "Interest"
        case .capital:  return "Capital"
        case .rate:     return "Interest Rate"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .interest: return "Amount earned / paid"
        case .capital:  return "Principal amount"
        case .rate:     return "Rate in %"
        }
    }

    var icon: String {
        switch self {
        case .interest: return "banknote"
        case .capital:  return "building.columns"
        case .rate:     return "percent"
        }
    }

    var accentColor: Color {
        switch self {
        case .interest: return Color(red: 1.00, green: 0.82, blue: 0.22)  // runtime: use fieldAccent()
        case .capital:  return Color(red: 0.28, green: 0.95, blue: 0.58)  // runtime: use fieldAccent()
        case .rate:     return Color(red: 0.95, green: 0.62, blue: 0.25)  // runtime: use fieldAccent()
        }
    }
}

// MARK: - Main View

struct InterestRateView: View {

    @Environment(\.colorScheme) private var colorScheme

    private var greenAccent: Color  { colorScheme == .dark ? Color(red: 0.28, green: 0.95, blue: 0.58) : Color(red: 0.05, green: 0.52, blue: 0.28) }
    private var goldAccent: Color   { colorScheme == .dark ? Color(red: 1.00, green: 0.82, blue: 0.22) : Color(red: 0.62, green: 0.42, blue: 0.00) }
    private var orangeAccent: Color { colorScheme == .dark ? Color(red: 0.95, green: 0.62, blue: 0.25) : Color(red: 0.72, green: 0.36, blue: 0.00) }
    private var glassTint: Color    { colorScheme == .dark ? Color(red: 0.06, green: 0.28, blue: 0.16) : Color(red: 0.04, green: 0.38, blue: 0.20) }

    private func fieldAccent(_ f: InterestField) -> Color {
        switch f {
        case .interest: return greenAccent
        case .capital:  return goldAccent
        case .rate:     return orangeAccent
        }
    }
    @State private var interestText: String = ""
    @State private var capitalText:  String = ""
    @State private var rateText:     String = ""
    @State private var solvedField:  InterestField? = nil
    @State private var resultPulse:  CGFloat = 1.0
    @FocusState private var focused: InterestField?

    // MARK: Helpers

    private func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: ".")
    }

    private var rateValue: Double? { Double(sanitize(rateText)) }

    // MARK: - Calculation

    private func calculate() {
        let z = Double(sanitize(interestText))
        let k = Double(sanitize(capitalText))
        let r = Double(sanitize(rateText))

        var solved: InterestField? = nil

        // Interest + Capital → Rate
        if let zi = z, let ka = k, rateText.trimmingCharacters(in: .whitespaces).isEmpty {
            let ir = InterestRate(zinsen: zi, kapital: ka)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                rateText    = ir.zinssatzToString
                solved      = .rate
            }
        }
        // Interest + Rate → Capital
        else if let zi = z, let ra = r, capitalText.trimmingCharacters(in: .whitespaces).isEmpty {
            let ir = InterestRate(zinsen: zi, zinssatz: ra)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                capitalText = ir.kapitalToString
                solved      = .capital
            }
        }
        // Capital + Rate → Interest
        else if let ka = k, let ra = r, interestText.trimmingCharacters(in: .whitespaces).isEmpty {
            let ir = InterestRate(zinssatz: ra, kapital: ka)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                interestText = ir.zinsenToString
                solved       = .interest
            }
        }

        if solved != nil {
            solvedField = solved
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { resultPulse = 1.08 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.2)) { resultPulse = 1.0 }
            }
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            interestText = ""; capitalText = ""; rateText = ""
            solvedField  = nil
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        // Gauge + fields side-by-side on first row when rate is known
                        if let r = rateValue, !rateText.isEmpty {
                            gaugeRow(rate: r)
                        }
                        inputCard(field: .interest, text: $interestText)
                        inputCard(field: .capital,  text: $capitalText)
                        inputCard(field: .rate,     text: $rateText)
                        controlRow
                        if solvedField != nil { resultCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .onTapGesture { focused = nil }
        }
        .navigationTitle("Interest Rate")
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
                Color(red: 0.02, green: 0.22, blue: 0.14),
                Color(red: 0.04, green: 0.30, blue: 0.18),
                Color(red: 0.02, green: 0.18, blue: 0.20),
                Color(red: 0.03, green: 0.26, blue: 0.16),
                Color(red: 0.06, green: 0.36, blue: 0.22),
                Color(red: 0.03, green: 0.22, blue: 0.22),
                Color(red: 0.02, green: 0.18, blue: 0.12),
                Color(red: 0.04, green: 0.28, blue: 0.16),
                Color(red: 0.03, green: 0.20, blue: 0.18)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(greenAccent.opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [greenAccent, goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Interest Rate Calculation")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Fill in two values — the third is solved automatically.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Gauge Row

    private func gaugeRow(rate: Double) -> some View {
        HStack(spacing: 16) {
            RateGaugeView(rate: rate)

            VStack(alignment: .leading, spacing: 10) {
                summaryRow(
                    icon: "banknote",
                    label: "Interest",
                    value: interestText,
                    color: InterestField.interest.accentColor
                )
                Divider().overlay(Color.primary.opacity(0.12))
                summaryRow(
                    icon: "building.columns",
                    label: "Capital",
                    value: capitalText,
                    color: InterestField.capital.accentColor
                )
                Divider().overlay(Color.primary.opacity(0.12))
                summaryRow(
                    icon: "percent",
                    label: "Rate",
                    value: rateText.isEmpty ? "—" : rateText + " %",
                    color: InterestField.rate.accentColor
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.tint(glassTint),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: rate)
    }

    private func summaryRow(icon: String, label: LocalizedStringKey, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color.opacity(0.80))
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.55))
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(value.isEmpty ? Color.primary.opacity(0.25) : Color.primary.opacity(0.90))
                .contentTransition(.numericText())
        }
    }

    // MARK: - Input Card

    @ViewBuilder
    private func inputCard(field: InterestField, text: Binding<String>) -> some View {
        let isSolved = solvedField == field

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(fieldAccent(field).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: field.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(fieldAccent(field))
            }
            .scaleEffect(isSolved ? resultPulse : 1.0)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(field.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(fieldAccent(field).opacity(0.88))
                    if isSolved {
                        Text("calculated")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(fieldAccent(field).opacity(0.60))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(fieldAccent(field).opacity(0.15), in: Capsule())
                    }
                }
                Text(field.subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.35))
                TextField("0.00", text: text)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: field)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(fieldAccent(field))
                    .onChange(of: text.wrappedValue) { _, newVal in
                        text.wrappedValue = newVal.replacingOccurrences(of: ",", with: ".")
                        solvedField = nil
                        calculate()
                    }
            }

            Spacer(minLength: 0)

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                    solvedField = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.primary.opacity(0.30))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            isSolved
                ? .regular.tint(glassTint)
                : .regular,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSolved)
    }

    // MARK: - Controls

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button(action: calculate) {
                Label(
                    "Calculate",
                    systemImage: "equal.circle.fill"
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glassProminent)

            Button(action: clearAll) {
                Label(
                    "Clear",
                    systemImage: "trash"
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.85))
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Result Card

    private var resultCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(greenAccent)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(resultSummary)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Interest = Rate × Capital ÷ 100")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.45))
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(
            .regular.tint(glassTint),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var resultSummary: String {
        let z = Double(sanitize(interestText)) ?? 0
        let k = Double(sanitize(capitalText))  ?? 0
        let r = Double(sanitize(rateText))     ?? 0
        let zFmt = z.formatted(.number.precision(.fractionLength(2)))
        let kFmt = k.formatted(.number.precision(.fractionLength(2)))
        let rFmt = r.formatted(.number.precision(.fractionLength(2)))
        return "\(zFmt) = \(rFmt)% of \(kFmt)"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        InterestRateView()
    }
}
