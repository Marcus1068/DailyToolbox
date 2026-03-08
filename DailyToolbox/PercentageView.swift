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
        case .rate:  return NSLocalizedString("Percentage %", comment: "Percentage %")
        case .value: return NSLocalizedString("Value", comment: "Value")
        case .base:  return NSLocalizedString("Base Value", comment: "Base Value")
        }
    }

    var placeholder: String {
        switch self {
        case .rate:  return "%"
        case .value: return NSLocalizedString("value", comment: "value")
        case .base:  return NSLocalizedString("base value", comment: "base value")
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

    // MARK: Compute

    private func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: ".")
    }

    private func calculate() {
        let rateVal  = Double(sanitize(rateText))
        let valueVal = Double(sanitize(valueText))
        let baseVal  = Double(sanitize(baseText))

        var newRate  = rateText
        var newValue = valueText
        var newBase  = baseText
        var solved: PercentField? = nil

        if let v = valueVal, let r = rateVal, baseText.trimmingCharacters(in: .whitespaces).isEmpty {
            let p = Percent(prozentwert: v, prozentsatz: r)
            newBase = p.grundWertToString
            solved = .base
        } else if let v = valueVal, let b = baseVal, rateText.trimmingCharacters(in: .whitespaces).isEmpty {
            let p = Percent(prozentwert: v, grundwert: b)
            newRate = p.prozentSatzToString
            solved = .rate
        } else if let r = rateVal, let b = baseVal, valueText.trimmingCharacters(in: .whitespaces).isEmpty {
            let p = Percent(prozentsatz: r, grundwert: b)
            newValue = p.prozentWertToString
            solved = .value
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if solved != nil {
                rateText  = newRate
                valueText = newValue
                baseText  = newBase
                solvedField = solved
                resultScale = 1.08
            }
        }
        if solved != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.25)) { resultScale = 1.0 }
            }
        }
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rateText  = ""
            valueText = ""
            baseText  = ""
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
                        controlRow
                        if solvedField != nil {
                            resultBadge
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle(NSLocalizedString("Percentage Calculation", comment: "Percentage Calculation"))
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
                Text(NSLocalizedString("Percentage Calculation", comment: "Percentage Calculation"))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(NSLocalizedString("Fill in any two fields — the third is solved automatically.", comment: "Fill in any two fields — the third is solved automatically."))
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
                        text.wrappedValue = newVal.replacingOccurrences(of: ",", with: ".")
                        solvedField = nil
                        calculate()
                    }
            }

            Spacer()

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                    solvedField = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            isSolved ? .regular.tint(Color(red: 0.10, green: 0.60, blue: 0.50)) : .regular,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSolved)
    }

    // MARK: - Controls

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button(action: calculate) {
                Label(
                    NSLocalizedString("Calculate", comment: "Calculate"),
                    systemImage: "equal.circle.fill"
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glassProminent)

            Button(action: clearAll) {
                Label(
                    NSLocalizedString("Clear", comment: "Clear"),
                    systemImage: "trash"
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
            }
            .buttonStyle(.glass)
        }
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
        guard let r = Double(rateText), let v = Double(valueText), let b = Double(baseText) else {
            return ""
        }
        let rFmt = r.formatted(.number.precision(.fractionLength(2)))
        let vFmt = v.formatted(.number.precision(.fractionLength(2)))
        let bFmt = b.formatted(.number.precision(.fractionLength(2)))
        return "\(vFmt) = \(rFmt)% of \(bFmt)"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PercentageView()
    }
}
