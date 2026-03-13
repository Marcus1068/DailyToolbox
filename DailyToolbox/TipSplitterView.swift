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
//  TipSplitterView.swift
//  DailyToolbox
//

import SwiftUI

struct TipSplitterView: View {

    @State private var billText: String = ""
    @State private var tipPercent: Double = 15
    @State private var people: Int = 2
    @State private var roundUp: Bool = false
    @FocusState private var billFocused: Bool

    private let presets: [Double] = [10, 15, 18, 20, 25]

    // MARK: Computed

    private var bill: Double? {
        Double(billText.replacingOccurrences(of: ",", with: "."))
    }

    private var tipAmount: Double { (bill ?? 0) * tipPercent / 100 }
    private var grandTotal: Double { (bill ?? 0) + tipAmount }

    private var perPersonTotal: Double {
        let raw = grandTotal / Double(max(1, people))
        return roundUp ? ceil(raw) : raw
    }
    private var perPersonTip: Double { tipAmount / Double(max(1, people)) }

    private let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.maximumFractionDigits = 2
        return f
    }()

    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

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

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 16) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { billCard }
                    GlassEffectContainer { tipCard }
                    GlassEffectContainer { peopleCard }
                    if bill != nil {
                        GlassEffectContainer { resultsCard }
                    } else {
                        GlassEffectContainer { emptyResultsCard }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { billFocused = false }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Tip Splitter")
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
                Color(red: 0.42, green: 0.26, blue: 0.02),
                Color(red: 0.50, green: 0.32, blue: 0.03),
                Color(red: 0.44, green: 0.24, blue: 0.02),
                Color(red: 0.48, green: 0.28, blue: 0.02),
                Color(red: 0.56, green: 0.38, blue: 0.04),
                Color(red: 0.42, green: 0.22, blue: 0.02),
                Color(red: 0.36, green: 0.20, blue: 0.01),
                Color(red: 0.46, green: 0.28, blue: 0.02),
                Color(red: 0.38, green: 0.20, blue: 0.02)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.00, green: 0.75, blue: 0.25).opacity(0.22))
                    .frame(width: 52, height: 52)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.00, green: 0.90, blue: 0.40),
                                     Color(red: 1.00, green: 0.65, blue: 0.15)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Tip Splitter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Bill & tip per person")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    billText = ""
                    tipPercent = 15
                    people = 2
                    roundUp = false
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.75))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Bill Input

    private var billCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bill Amount", systemImage: "banknote.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.85))

            HStack(spacing: 10) {
                Text(currencyFormatter.currencySymbol ?? "$")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary.opacity(0.50))

                TextField("0.00", text: $billText)
                    .keyboardType(.decimalPad)
                    .focused($billFocused)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(Color(red: 1.00, green: 0.82, blue: 0.35))
                    .onChange(of: billText) { _, newVal in
                        let filtered = numericOnly(newVal)
                        if filtered != newVal { billText = filtered }
                    }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Tip Picker

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Tip Percentage", systemImage: "percent")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.85))
                Spacer()
                Text("\(Int(tipPercent))%")
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color(red: 1.00, green: 0.90, blue: 0.45))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: tipPercent)
            }

            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            tipPercent = preset
                        }
                    } label: {
                        Text("\(Int(preset))%")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(tipPercent == preset ? .black : Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tipPercent == preset
                                          ? Color(red: 1.00, green: 0.85, blue: 0.30)
                                          : Color.primary.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Fine-tune stepper
            HStack(spacing: 16) {
                Text("Custom")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
                Spacer()
                HStack(spacing: 0) {
                    stepperButton(systemImage: "minus") {
                        if tipPercent > 0 { tipPercent = max(0, tipPercent - 1) }
                    }
                    Text("\(Int(tipPercent))%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                        .frame(minWidth: 48)
                        .multilineTextAlignment(.center)
                    stepperButton(systemImage: "plus") {
                        tipPercent = min(100, tipPercent + 1)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.10))
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - People Picker

    private var peopleCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.00, green: 0.75, blue: 0.25).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Number of People")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.85))
                Text("\(people) \(people == 1 ? String(localized: "person") : String(localized: "people"))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: people)
            }

            Spacer()

            HStack(spacing: 0) {
                stepperButton(systemImage: "minus") {
                    if people > 1 { people -= 1 }
                }
                Text("\(people)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: people)
                stepperButton(systemImage: "plus") {
                    if people < 30 { people += 1 }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.10))
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Results

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("Results", systemImage: "equal.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.85))
                Spacer()
                Toggle("Round Up", isOn: $roundUp)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.00, green: 0.75, blue: 0.25)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.70))
                    .labelsHidden()
                Text("Round Up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            .padding(.bottom, 14)

            Divider().background(Color.primary.opacity(0.12))
                .padding(.bottom, 14)

            // Totals
            resultRow(label: "Bill Amount",  value: formatCurrency(bill ?? 0))
            resultRow(label: "Tip (\(Int(tipPercent))%)", value: formatCurrency(tipAmount))
            resultRow(label: "Grand Total",  value: formatCurrency(grandTotal), accent: true)

            if people > 1 {
                Divider().background(Color.primary.opacity(0.12))
                    .padding(.vertical, 12)

                Text("Per Person (\(people))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.75))
                    .padding(.bottom, 8)

                resultRow(label: "Tip",         value: formatCurrency(perPersonTip))
                resultRow(label: "Total",        value: formatCurrency(perPersonTotal), accent: true, large: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.tint(Color(red: 1.00, green: 0.70, blue: 0.10).opacity(0.18)),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var emptyResultsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "banknote")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.primary.opacity(0.35))
            Text("Enter a bill amount to see results")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.40))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Sub-Views

    @ViewBuilder
    private func resultRow(
        label: String,
        value: String,
        accent: Bool = false,
        large: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(large ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(accent ? Color.primary : Color.primary.opacity(0.65))
            Spacer()
            Text(value)
                .font(large
                      ? .title2.weight(.bold).monospacedDigit()
                      : .subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(accent
                                 ? Color(red: 1.00, green: 0.88, blue: 0.40)
                                 : Color.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: value)
        }
        .padding(.bottom, large ? 0 : 8)
    }

    @ViewBuilder
    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TipSplitterView()
    }
}
