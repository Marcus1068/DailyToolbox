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

    var label: LocalizedStringKey {
        switch self {
        case .rate:  return "Percentage %"
        case .value: return "Value"
        case .base:  return "Base Value"
        }
    }

    var placeholder: LocalizedStringKey {
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

// MARK: - History Entry

private struct PercentEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let rate: Double
    let value: Double
    let base: Double
}

// MARK: - View

struct PercentageView: View {

    @State private var rateText:  String
    @State private var valueText: String
    @State private var baseText:  String

    @State private var solvedField: PercentField? = nil
    @State private var resultScale: CGFloat = 1.0
    @FocusState private var focusedField: PercentField?
    @AppStorage("percent.history") private var historyJSON = "[]"

    init(previewRate: String = "", previewValue: String = "", previewBase: String = "") {
        _rateText  = State(initialValue: previewRate)
        _valueText = State(initialValue: previewValue)
        _baseText  = State(initialValue: previewBase)
    }

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

        if let v = valueVal, let r = rateVal, r != 0, baseEmpty {
            // base = value / rate * 100
            newBase = String(format: "%g", v / r * 100.0)
            solved = .base
        } else if let v = valueVal, let b = baseVal, b != 0, rateEmpty {
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
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
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

    private func clearField(_ f: PercentField) {
        switch f {
        case .rate:  rateText  = ""
        case .value: valueText = ""
        case .base:  baseText  = ""
        }
    }

    // MARK: History

    private var historyEntries: [PercentEntry] {
        guard let data = historyJSON.data(using: .utf8),
              let entries = try? JSONDecoder().decode([PercentEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func recordHistory() {
        guard let r = parse(rateText),
              let v = parse(valueText),
              let b = parse(baseText) else { return }
        let entry = PercentEntry(id: UUID(), date: Date(), rate: r, value: v, base: b)
        // Skip if same as most recent
        if let last = historyEntries.first,
           abs(last.rate  - r) < 0.0001,
           abs(last.value - v) < 0.0001,
           abs(last.base  - b) < 0.0001 { return }
        var entries = historyEntries
        entries.insert(entry, at: 0)
        if entries.count > 10 { entries = Array(entries.prefix(10)) }
        if let data = try? JSONEncoder().encode(entries),
           let json = String(data: data, encoding: .utf8) { historyJSON = json }
    }

    private func clearHistory() { historyJSON = "[]" }

    // MARK: Body

    @Environment(\.colorScheme) private var colorScheme

    // MARK: Adaptive accent (bright teal in dark, deep teal in light)
    private var tealAccent: Color {
        colorScheme == .dark ? Color(red: 0.20, green: 0.85, blue: 0.72)
                             : Color(red: 0.02, green: 0.55, blue: 0.42)
    }
    private var tealGlass: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.65, blue: 0.54)
                             : Color(red: 0.02, green: 0.42, blue: 0.32)
    }

    var body: some View {
        ZStack {
            background
            // ScrollView sits outside any GlassEffectContainer so that each
            // card row can manage its own glass scope — this ensures the xmark
            // buttons in ZStack are genuinely above the glass rendering layer.
            ScrollView {
                VStack(spacing: 24) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { howToCard }
                    inputSection
                    GlassEffectContainer { clearButton }
                    if solvedField != nil {
                        GlassEffectContainer { resultBadge }
                    }
                    if !historyEntries.isEmpty {
                        GlassEffectContainer { historyCard }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .navigationTitle("Percentage Calculation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focusedField = nil }

        .accessibilityAddTraits(.isButton)

        .accessibilityLabel("Dismiss keyboard")
        // Record history 2 s after the last change — avoids logging every keystroke
        .task(id: "\(rateText)|\(valueText)|\(baseText)") {
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            if solvedField != nil { recordHistory() }
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

    // MARK: - How To Card

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("How it works", systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tealAccent)

            Text("Enter any two of the three values — the missing one is calculated instantly.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(tealAccent.opacity(0.25))

            VStack(spacing: 10) {
                formulaRow(
                    icon: "number",
                    label: "Find the Value",
                    formula: "Value = Rate % × Base",
                    example: "e.g. 15% of 200 = 30"
                )
                formulaRow(
                    icon: "percent",
                    label: "Find the Rate",
                    formula: "Rate = Value ÷ Base × 100",
                    example: "e.g. 30 ÷ 200 × 100 = 15 %"
                )
                formulaRow(
                    icon: "square.stack.3d.up",
                    label: "Find the Base",
                    formula: "Base = Value ÷ Rate × 100",
                    example: "e.g. 30 ÷ 15 × 100 = 200"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private func formulaRow(icon: String, label: LocalizedStringKey,
                            formula: LocalizedStringKey, example: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tealAccent)
                .frame(width: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.85))
                Text(formula)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.65))
                Text(example)
                    .font(.caption2)
                    .foregroundStyle(tealAccent.opacity(0.85))
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tealAccent.opacity(0.22))
                    .frame(width: 54, height: 54)
                Image(systemName: "percent")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(tealAccent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Percentage Calculation")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Fill in any two fields — the third is solved automatically.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Input Section

    private var hasAnyInput: Bool {
        !rateText.isEmpty || !valueText.isEmpty || !baseText.isEmpty
    }

    private var inputSection: some View {
        VStack(spacing: 12) {
            cardRow(field: .rate,  text: $rateText)
            cardRow(field: .value, text: $valueText)
            cardRow(field: .base,  text: $baseText)
        }
    }

    // ZStack places the button ABOVE the GlassEffectContainer — the glass
    // compositing scope is limited to just the card, so z-ordering is correct.
    @ViewBuilder
    private func cardRow(field: PercentField, text: Binding<String>) -> some View {
        ZStack(alignment: .trailing) {
            GlassEffectContainer {
                inputCard(field: field, text: text)
            }
            if hasAnyInput {
                Button(action: clearAll) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .shadow(color: .black.opacity(0.4), radius: 3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
    }

    @ViewBuilder
    private func inputCard(field: PercentField, text: Binding<String>) -> some View {
        let isSolved = solvedField == field
        let accentColor: Color = isSolved
            ? tealAccent
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
                    .foregroundStyle(Color.primary)
                    .tint(tealAccent)
                    .onChange(of: text.wrappedValue) { _, newVal in
                        // Ignore programmatic updates from calculate()
                        guard focusedField == field else { return }
                        let filtered = numericOnly(newVal)
                        if filtered != newVal {
                            text.wrappedValue = filtered
                            return
                        }
                        // If the user edits an input field while another field
                        // shows a computed result, clear that result first so
                        // calculate() always has exactly one empty slot to solve.
                        if let prev = solvedField, prev != field {
                            clearField(prev)
                        }
                        solvedField = nil
                        calculate()
                    }
            }

            // Reserve trailing space so text doesn't run under the xmark
            if hasAnyInput { Color.clear.frame(width: 36, height: 1) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            isSolved ? .regular.tint(tealGlass) : .regular,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSolved)
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button(action: clearAll) {
            Label("Clear All", systemImage: "trash")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Result Badge

    private var resultBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(tealAccent)
                .font(.system(size: 20))
            Text(resultSummary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular.tint(tealGlass), in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var resultSummary: String {
        guard let r = parse(rateText),
              let v = parse(valueText),
              let b = parse(baseText) else { return "" }
        let rFmt = r.formatted(.number.precision(.fractionLength(2)))
        let vFmt = v.formatted(.number.precision(.fractionLength(2)))
        let bFmt = b.formatted(.number.precision(.fractionLength(2)))
        let fmt = NSLocalizedString("%@ = %@%% of %@", comment: "Percentage result summary")
        return String(format: fmt, vFmt, rFmt, bFmt)
    }
    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Recent Calculations", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tealAccent)
                Spacer()
                Button(action: clearHistory) {
                    Text("Clear")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.50))
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(tealAccent.opacity(0.25))

            VStack(spacing: 0) {
                ForEach(historyEntries) { entry in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            rateText  = String(format: "%g", entry.rate)
                            valueText = String(format: "%g", entry.value)
                            baseText  = String(format: "%g", entry.base)
                            solvedField = nil
                        }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    entryChip(
                                        label: "Rate",
                                        value: entry.rate.formatted(.number.precision(.fractionLength(2))) + "%"
                                    )
                                    Image(systemName: "arrow.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.primary.opacity(0.30))
                                    entryChip(
                                        label: "Value",
                                        value: entry.value.formatted(.number.precision(.fractionLength(2)))
                                    )
                                    Text("of")
                                        .font(.caption2)
                                        .foregroundStyle(Color.primary.opacity(0.40))
                                    entryChip(
                                        label: "Base",
                                        value: entry.base.formatted(.number.precision(.fractionLength(2)))
                                    )
                                }
                                Text(entry.date, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(Color.primary.opacity(0.35))
                            }
                            Spacer()
                            Image(systemName: "arrow.uturn.left")
                                .font(.caption2)
                                .foregroundStyle(Color.primary.opacity(0.25))
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if entry.id != historyEntries.last?.id {
                        Divider().overlay(Color.primary.opacity(0.08))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    @ViewBuilder
    private func entryChip(label: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(tealAccent.opacity(0.70))
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PercentageView()
    }
}
