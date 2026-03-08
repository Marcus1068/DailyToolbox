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
//  PercentageView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

// MARK: - Field identity

private enum PercentField: CaseIterable {
    case rate, value, base

    var label: String {
        switch self {
        case .rate:  return "Percentage %"
        case .value: return "Value"
        case .base:  return "Base Value"
        }
    }

    var placeholder: String {
        switch self {
        case .rate:  return "%"
        case .value: return "value"
        case .base:  return "base value"
        }
    }

    var icon: String {
        switch self {
        case .rate:  return "percent"
        case .value: return "number"
        case .base:  return "square.stack.3d.up"
        }
    }
}

// MARK: - View

struct PercentageView: View {

    @State private var rateText:  String = ""
    @State private var valueText: String = ""
    @State private var baseText:  String = ""

    @State private var solvedField: PercentField? = nil
    @State private var resultScale: CGFloat = 1.0
    @FocusState private var focusedField: PercentField?

    // MARK: Helpers

    /// Allow digits and at most one decimal point; replace comma with dot.
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

    /// Parse a field string to Double (safe for both user input and computed output).
    private func parse(_ s: String) -> Double? {
        Double(s.filter { $0.isNumber || $0 == "." })
    }

    // MARK: Compute

    private func calculate() {
        let rateVal  = parse(rateText)
        let valueVal = parse(valueText)
        let baseVal  = parse(baseText)

        let rateEmpty  = rateText.trimmingCharacters(in: .whitespaces).isEmpty
        let valueEmpty = valueText.trimmingCharacters(in: .whitespaces).isEmpty
        let baseEmpty  = baseText.trimmingCharacters(in: .whitespaces).isEmpty

        var solved: PercentField? = nil
        var newRate  = rateText
        var newValue = valueText
        var newBase  = baseText

        if let v = valueVal, let r = rateVal, baseEmpty {
            // base = value / rate * 100
            newBase = String(format: "%g", v / r * 100.0)
            solved = .base
        } else if let v = valueVal, let b = baseVal, rateEmpty {
            // rate = value / base * 100
            newRate = String(format: "%g", v / b * 100.0)
            solved = .rate
        } else if let r = rateVal, let b = baseVal, valueEmpty {
            // value = rate * base / 100
            newValue = String(format: "%g", r * b / 100.0)
            solved = .value
        }

        guard let solved else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            rateText    = newRate
            valueText   = newValue
            baseText    = newBase
            solvedField = solved
            resultScale = 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.25)) { resultScale = 1.0 }
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rateText    = ""
            valueText   = ""
            baseText    = ""
            solvedField = nil
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 24) {
                        headerCard
                        inputSection
                        clearButton
                        if solvedField != nil {
                            resultBadge
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("Percentage Calculation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focusedField = nil }
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
                Color(red: 0.02, green: 0.38, blue: 0.40),
                Color(red: 0.04, green: 0.52, blue: 0.46),
                Color(red: 0.00, green: 0.32, blue: 0.56),
                Color(red: 0.05, green: 0.50, blue: 0.44),
                Color(red: 0.10, green: 0.65, blue: 0.54),
                Color(red: 0.02, green: 0.42, blue: 0.62),
                Color(red: 0.04, green: 0.46, blue: 0.38),
                Color(red: 0.08, green: 0.60, blue: 0.50),
                Color(red: 0.00, green: 0.36, blue: 0.58)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.10, green: 0.75, blue: 0.60).opacity(0.22))
                    .frame(width: 54, height: 54)
                Image(systemName: "percent")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.95, blue: 0.75))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Percentage Calculation")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Fill in any two fields — the third is solved automatically.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            inputCard(field: .rate,  text: $rateText)
            inputCard(field: .value, text: $valueText)
            inputCard(field: .base,  text: $baseText)
        }
    }

    @ViewBuilder
    private func inputCard(field: PercentField, text: Binding<String>) -> some View {
        let isSolved = solvedField == field
        let accentColor: Color = isSolved
            ? Color(red: 0.20, green: 0.95, blue: 0.75)
            : .white

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: field.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            .scaleEffect(isSolved ? resultScale : 1.0)

            VStack(alignment: .leading, spacing: 3) {
                Text(field.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor.opacity(0.85))

                TextField(field.placeholder, text: text)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
                    .tint(Color(red: 0.20, green: 0.95, blue: 0.75))
                    .onChange(of: text.wrappedValue) { _, newVal in
                        // Ignore programmatic updates from calculate()
                        guard focusedField == field else { return }
                        let filtered = numericOnly(newVal)
                        if filtered != newVal {
                            text.wrappedValue = filtered
                            return
                        }
                        solvedField = nil
                        calculate()
                    }
            }

            // Reserve space so the glass card stays consistent width
            if !rateText.isEmpty || !valueText.isEmpty || !baseText.isEmpty {
                Color.clear.frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            isSolved ? .regular.tint(Color(red: 0.10, green: 0.60, blue: 0.50)) : .regular,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSolved)
        // Xmark sits as an overlay ON TOP of the glass surface so touches
        // are never blocked by the glass effect hit-test area.
        .overlay(alignment: .trailing) {
            if !rateText.isEmpty || !valueText.isEmpty || !baseText.isEmpty {
                Button(action: clearAll) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 44, height: 44)      // generous hit target
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button(action: clearAll) {
            Label("Clear All", systemImage: "trash")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Result Badge

    private var resultBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.20, green: 0.95, blue: 0.75))
                .font(.system(size: 20))
            Text(resultSummary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular.tint(Color(red: 0.05, green: 0.55, blue: 0.45)), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var resultSummary: String {
        guard let r = parse(rateText),
              let v = parse(valueText),
              let b = parse(baseText) else { return "" }
        let rFmt = r.formatted(.number.precision(.fractionLength(2)))
        let vFmt = v.formatted(.number.precision(.fractionLength(2)))
        let bFmt = b.formatted(.number.precision(.fractionLength(2)))
        return "\(vFmt) = \(rFmt)% of \(bFmt)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PercentageView()
    }
}
