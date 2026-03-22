/*

Copyright 2020-2026 Marcus Deuß

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

// MARK: - History Entry

private struct ConversionEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let fromCode: String
    let toCode: String
    let amount: Double
    let result: Double
}

// MARK: - Rate Snapshot

private struct RateSnapshot: Codable {
    let dateStr:  String  // "yyyy-MM-dd"
    let fromCode: String
    let toCode:   String
    let rate:     Double
}

// MARK: - Load State

private enum ConverterLoadState {
    case loading
    case loaded
    case failed(String)
}

private enum CurrencyLoadError: LocalizedError {
    case noRates
    var errorDescription: String? {
        "Could not load exchange rates. Please check your internet connection."
    }
}

// MARK: - Sparkline Shape

private struct SparklineShape: Shape {
    let values: [Double]
    func path(in rect: CGRect) -> Path {
        guard values.count >= 2 else { return Path() }
        let lo = values.min()!
        let hi = values.max()!
        let range = hi - lo
        func pt(_ i: Int) -> CGPoint {
            let x = rect.minX + CGFloat(i) / CGFloat(values.count - 1) * rect.width
            let y = range == 0 ? rect.midY
                               : rect.maxY - CGFloat((values[i] - lo) / range) * rect.height
            return CGPoint(x: x, y: y)
        }
        var path = Path()
        path.move(to: pt(0))
        for i in 1..<values.count { path.addLine(to: pt(i)) }
        return path
    }
}

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
        NavigationStack {
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Main View

struct CurrencyConverterView: View {

    @State private var cvt: CurrencyConverter?
    @State private var loadState: ConverterLoadState = .loading
    @State private var showClearHistoryConfirm = false
    @AppStorage("currency.from")          private var fromCurrency    = "EUR"
    @AppStorage("currency.to")            private var toCurrency      = "USD"
    @AppStorage("currency.amount")        private var amountText      = "1.00"
    @AppStorage("currency.history")       private var historyJSON     = "[]"
    @AppStorage("currency.rateSnapshots") private var rateSnapshotsJSON = "[]"
    @State private var showFromPicker = false
    @State private var showToPicker   = false
    @State private var swapRotation: Double = 0
    @FocusState private var amountFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var purpleAccent: Color  { colorScheme == .dark ? Color(red: 0.68, green: 0.56, blue: 1.0) : Color(red: 0.42, green: 0.18, blue: 0.88) }
    private var purpleAccent2: Color { colorScheme == .dark ? Color(red: 0.90, green: 0.70, blue: 1.0) : Color(red: 0.55, green: 0.28, blue: 0.95) }
    private var resultGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(colors: [Color(red: 0.80, green: 0.68, blue: 1.0), Color(red: 0.92, green: 0.78, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [Color(red: 0.42, green: 0.18, blue: 0.88), Color(red: 0.55, green: 0.28, blue: 0.95)], startPoint: .leading, endPoint: .trailing)
    }
    private var glassTint: Color { colorScheme == .dark ? Color(red: 0.30, green: 0.10, blue: 0.55) : Color(red: 0.22, green: 0.08, blue: 0.45) }

    // Default init used at runtime
    init() {}

#if DEBUG
    /// Preview-only init: skips the network load and pre-populates with mock data.
    fileprivate init(preview cvt: CurrencyConverter) {
        _cvt = State(initialValue: cvt)
        _loadState = State(initialValue: .loaded)
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

    private var resultShareText: String {
        "\(amountText) \(fromCurrency) = \(resultFormatted) \(toCurrency)"
    }

    // MARK: History helpers

    private var historyEntries: [ConversionEntry] {
        guard let data = historyJSON.data(using: .utf8),
              let entries = try? JSONDecoder().decode([ConversionEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func recordHistory() {
        guard let res = result,
              let amount = Double(sanitized), amount > 0 else { return }
        let entry = ConversionEntry(
            id: UUID(), date: Date(),
            fromCode: fromCurrency, toCode: toCurrency,
            amount: amount, result: res
        )
        // Skip if identical to the most recent entry
        if let last = historyEntries.first,
           last.fromCode == entry.fromCode,
           last.toCode   == entry.toCode,
           abs(last.amount - entry.amount) < 0.001 { return }
        var entries = historyEntries
        entries.insert(entry, at: 0)
        if entries.count > 10 { entries = Array(entries.prefix(10)) }
        if let data = try? JSONEncoder().encode(entries),
           let json = String(data: data, encoding: .utf8) { historyJSON = json }
    }

    private func clearHistory() { historyJSON = "[]" }

    // MARK: Rate Snapshot

    private var rateSnapshots: [RateSnapshot] {
        (try? JSONDecoder().decode(
            [RateSnapshot].self,
            from: rateSnapshotsJSON.data(using: .utf8) ?? Data()
        )) ?? []
    }

    private var sparklineData: [RateSnapshot] {
        rateSnapshots
            .filter { $0.fromCode == fromCurrency && $0.toCode == toCurrency }
            .sorted { $0.dateStr < $1.dateStr }
            .suffix(7)
            .map { $0 }
    }

    private func recordRateSnapshot() {
        guard let rate = unitRate else { return }
        let dateStr = Date().formatted(.iso8601.year().month().day())
        var snaps = rateSnapshots
        snaps.removeAll { $0.dateStr == dateStr
                       && $0.fromCode == fromCurrency
                       && $0.toCode   == toCurrency }
        snaps.append(RateSnapshot(dateStr: dateStr,
                                  fromCode: fromCurrency,
                                  toCode: toCurrency,
                                  rate: rate))
        if snaps.count > 90 { snaps = Array(snaps.suffix(90)) }
        if let data = try? JSONEncoder().encode(snaps),
           let json = String(data: data, encoding: .utf8) { rateSnapshotsJSON = json }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            switch loadState {
            case .loading:
                loadingView
            case .failed(let message):
                errorView(message)
            case .loaded:
                GlassEffectContainer {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerCard
                            amountCard
                            conversionCard
                            resultCard
                            rateInfoCard
                            if sparklineData.count >= 2 {
                                sparklineCard
                            }
                            if !historyEntries.isEmpty {
                                historyCard
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                    }
                }
                .onTapGesture { amountFocused = false }

                .accessibilityAddTraits(.isButton)

                .accessibilityLabel("Dismiss keyboard")
            }
        }
        .navigationTitle("Currency Converter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadConverter() }
        // Auto-record after 1 s of no changes
        .task(id: "\(amountText)|\(fromCurrency)|\(toCurrency)") {
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            recordHistory()
            recordRateSnapshot()
        }
        .sheet(isPresented: $showFromPicker) {
            CurrencyPickerSheet(currencies: currencies, selected: $fromCurrency)
        }
        .sheet(isPresented: $showToPicker) {
            CurrencyPickerSheet(currencies: currencies, selected: $toCurrency)
        }
        .confirmationDialog("Clear conversion history?", isPresented: $showClearHistoryConfirm) {
            Button("Clear All", role: .destructive) { clearHistory() }
            Button("Cancel", role: .cancel) {}
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

    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Recent Conversions", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(purpleAccent)
                Spacer()
                Button { showClearHistoryConfirm = true } label: {
                    Text("Clear")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.50))
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(purpleAccent.opacity(0.20))

            VStack(spacing: 0) {
                ForEach(historyEntries) { entry in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            amountText   = String(format: "%g", entry.amount)
                            fromCurrency = entry.fromCode
                            toCurrency   = entry.toCode
                        }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 5) {
                                    Text(entry.amount.formatted(.number.precision(.fractionLength(2))))
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(Color.primary)
                                    Text(entry.fromCode)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.primary.opacity(0.55))
                                    Image(systemName: "arrow.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.primary.opacity(0.35))
                                    Text(entry.result.formatted(.number.precision(.fractionLength(2))))
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(purpleAccent2)
                                    Text(entry.toCode)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(purpleAccent.opacity(0.70))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
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

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.45))
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary.opacity(0.65))
                .padding(.horizontal, 32)
            Button("Retry") {
                Task { await loadConverter() }
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(purpleAccent.opacity(0.18))
                    .frame(width: 54, height: 54)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [purpleAccent2, purpleAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Currency Converter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Live exchange rates · 160+ currencies")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
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
                    .tint(purpleAccent)
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Conversion Card (from / swap / to)

    private var conversionCard: some View {
        HStack(spacing: 12) {
            currencyButton(
                code: fromCurrency,
                label: "From",
                accentColor: purpleAccent
            ) { showFromPicker = true }

            swapButton

            currencyButton(
                code: toCurrency,
                label: "To",
                accentColor: purpleAccent2
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
            HStack {
                Label(
                    "Result",
                    systemImage: "equal.circle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.70))

                Spacer()

                if result != nil {
                    Button {
                        UIPasteboard.general.string = resultShareText
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Copy")

                    ShareLink(item: resultShareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(resultFormatted)
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        resultGradient
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
            .regular.tint(glassTint),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    // MARK: - Sparkline Card

    private var sparklineCard: some View {
        let snaps  = sparklineData
        let values = snaps.map(\.rate)
        let lo     = values.min() ?? 0
        let hi     = values.max() ?? 0
        let first  = values.first ?? 0
        let last   = values.last  ?? 0
        let up     = last >= first
        return GlassEffectContainer(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.caption.weight(.semibold))
                        Text("7-Day Trend")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.primary.opacity(0.55))
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2.weight(.bold))
                        let delta = last - first
                        Text(delta >= 0 ? "+\(String(format: "%.4f", delta))"
                                        : String(format: "%.4f", delta))
                            .font(.caption2.weight(.semibold).monospacedDigit())
                    }
                    .foregroundStyle(up ? Color.green : Color.red)
                }

                SparklineShape(values: values)
                    .stroke(
                        LinearGradient(
                            colors: [glassTint, glassTint.opacity(0.5)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .frame(height: 52)
                    .overlay(alignment: .bottomLeading) {
                        Text(String(format: "%.4f", lo))
                            .font(.system(size: 8, weight: .medium).monospacedDigit())
                            .foregroundStyle(Color.primary.opacity(0.45))
                    }
                    .overlay(alignment: .topLeading) {
                        Text(String(format: "%.4f", hi))
                            .font(.system(size: 8, weight: .medium).monospacedDigit())
                            .foregroundStyle(Color.primary.opacity(0.45))
                    }

                HStack {
                    Text(snaps.first?.dateStr ?? "")
                    Spacer()
                    Text(snaps.last?.dateStr ?? "")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.35))
            }
            .padding(16)
        }
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Load

    @MainActor
    private func loadConverter() async {
        loadState = .loading
        do {
            let converter = await CurrencyConverter.load()
            let list = converter.getCurrencyStrings()
            guard !list.isEmpty else {
                throw CurrencyLoadError.noRates
            }
            cvt = converter
            // Only fall back to defaults if the saved codes are not in the loaded list
            if !list.contains(fromCurrency), let first = list.first { fromCurrency = first }
            if !list.contains(toCurrency),  list.count > 1            { toCurrency  = list[1] }
            loadState = .loaded
            recordRateSnapshot()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        CurrencyConverterView(preview: .preview)
    }
}
#endif
