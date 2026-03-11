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
//  CurrencyConverterView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

// MARK: - Currency Picker Sheet

private struct CurrencyPickerSheet: View {
    let currencies: [String]
    @Binding var selected: String
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: [String] {
        search.isEmpty ? currencies : currencies.filter {
            $0.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationView {
            List(filtered, id: \.self) { code in
                Button {
                    selected = code
                    dismiss()
                } label: {
                    HStack {
                        Text(code)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if code == selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search currencies"
            )
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Global.cancel) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Main View

struct CurrencyConverterView: View {

    @State private var cvt: CurrencyConverter?
    @State private var isLoading = true
    @AppStorage("currency.from")   private var fromCurrency = "EUR"
    @AppStorage("currency.to")     private var toCurrency   = "USD"
    @AppStorage("currency.amount") private var amountText   = "1.00"
    @State private var showFromPicker = false
    @State private var showToPicker   = false
    @State private var swapRotation: Double = 0
    @FocusState private var amountFocused: Bool

    // Default init used at runtime
    init() {}

#if DEBUG
    /// Preview-only init: skips the network load and pre-populates with mock data.
    fileprivate init(preview cvt: CurrencyConverter) {
        _cvt = State(initialValue: cvt)
        _isLoading = State(initialValue: false)
        _toCurrency = AppStorage(wrappedValue: "USD", "currency.to")
    }
#endif

    // MARK: Helpers

    private var currencies: [String] { cvt?.getCurrencyStrings() ?? [] }

    private var sanitized: String {
        amountText.replacingOccurrences(of: ",", with: ".")
    }

    private var result: Double? {
        guard let cvt, let amount = Double(sanitized), amount.isFinite else { return nil }
        return cvt.convertFromTo(baseCurrency: fromCurrency, destCurrency: toCurrency) * amount
    }

    private var unitRate: Double? {
        cvt?.convertFromTo(baseCurrency: fromCurrency, destCurrency: toCurrency)
    }

    private var resultFormatted: String {
        result.map { $0.formatted(.number.precision(.fractionLength(2))) } ?? "—"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            if isLoading {
                loadingView
            } else {
                GlassEffectContainer {
                    ScrollView {
                        VStack(spacing: 20) {
                            amountCard
                            conversionCard
                            resultCard
                            rateInfoCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                    }
                }
                .onTapGesture { amountFocused = false }
            }
        }
        .navigationTitle("Currency Converter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadConverter() }
        .sheet(isPresented: $showFromPicker) {
            CurrencyPickerSheet(currencies: currencies, selected: $fromCurrency)
        }
        .sheet(isPresented: $showToPicker) {
            CurrencyPickerSheet(currencies: currencies, selected: $toCurrency)
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
                Color(red: 0.08, green: 0.04, blue: 0.36),
                Color(red: 0.16, green: 0.08, blue: 0.50),
                Color(red: 0.32, green: 0.04, blue: 0.44),
                Color(red: 0.10, green: 0.06, blue: 0.46),
                Color(red: 0.22, green: 0.12, blue: 0.58),
                Color(red: 0.38, green: 0.08, blue: 0.50),
                Color(red: 0.06, green: 0.10, blue: 0.42),
                Color(red: 0.18, green: 0.14, blue: 0.52),
                Color(red: 0.28, green: 0.06, blue: 0.46)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.primary)
                .scaleEffect(1.4)
            Text("Fetching rates…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.75))
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "Amount",
                systemImage: "banknote"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.70))

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(Color(red: 0.68, green: 0.56, blue: 1.0))
                    .onChange(of: amountText) { _, val in
                        amountText = val.replacingOccurrences(of: ",", with: ".")
                    }

                Text(fromCurrency)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .padding(.bottom, 4)
            }

            Divider()
                .overlay(Color.primary.opacity(0.15))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Conversion Card (from / swap / to)

    private var conversionCard: some View {
        HStack(spacing: 12) {
            currencyButton(
                code: fromCurrency,
                label: "From",
                accentColor: Color(red: 0.68, green: 0.56, blue: 1.0)
            ) { showFromPicker = true }

            swapButton

            currencyButton(
                code: toCurrency,
                label: "To",
                accentColor: Color(red: 0.90, green: 0.70, blue: 1.0)
            ) { showToPicker = true }
        }
    }

    @ViewBuilder
    private func currencyButton(
        code: String,
        label: LocalizedStringKey,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor.opacity(0.80))
                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.primary.opacity(0.40))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(.glass)
    }

    private var swapButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                swap(&fromCurrency, &toCurrency)
                swapRotation += 180
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.85))
                .rotationEffect(.degrees(swapRotation))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "Result",
                systemImage: "equal.circle"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.70))

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(resultFormatted)
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.80, green: 0.68, blue: 1.0),
                                Color(red: 0.92, green: 0.78, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: resultFormatted)

                Text(toCurrency)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .padding(.bottom, 4)
            }

            Divider()
                .overlay(Color.primary.opacity(0.15))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .glassEffect(
            .regular.tint(Color(red: 0.30, green: 0.10, blue: 0.55)),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    // MARK: - Rate Info Card

    private var rateInfoCard: some View {
        VStack(spacing: 10) {
            if let rate = unitRate {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.primary.opacity(0.55))
                        .font(.caption)
                    Text("1 \(fromCurrency) = \(rate.formatted(.number.precision(.fractionLength(4)))) \(toCurrency)")
                        .font(.subheadline.weight(.medium).monospacedDigit())
                        .foregroundStyle(Color.primary.opacity(0.80))
                }
            }

            Divider().overlay(Color.primary.opacity(0.12))

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.45))
                Text("Last update:")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.45))
                Text(cvt?.getLastUpdate() ?? "—")
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.60))
            }

            HStack(spacing: 6) {
                Image(systemName: "building.columns")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.35))
                Text("Source: European Central Bank")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.40))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Load

    @MainActor
    private func loadConverter() async {
        let converter = await CurrencyConverter.load()
        cvt = converter
        let list = converter.getCurrencyStrings()
        // Only fall back to defaults if the saved codes are not in the loaded list
        if !list.contains(fromCurrency), let first = list.first { fromCurrency = first }
        if !list.contains(toCurrency),  list.count > 1            { toCurrency  = list[1] }
        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        CurrencyConverterView(preview: .preview)
    }
}
#endif
