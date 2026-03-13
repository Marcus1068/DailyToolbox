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
//  DecimalRomanNumbersView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Constants

private let romanSymbols: [(symbol: String, value: Int, sub: String)] = [
    ("M",  1000, "mille"),
    ("D",   500, "quingenti"),
    ("C",   100, "centum"),
    ("L",    50, "quinquaginta"),
    ("X",    10, "decem"),
    ("V",     5, "quinque"),
    ("I",     1, "unus"),
]

private let subtractivePairs: [(roman: String, value: Int)] = [
    ("CM", 900), ("CD", 400), ("XC", 90), ("XL", 40), ("IX", 9), ("IV", 4),
]

private let invalidPairs: Set<String> = [
    "IM","ID","IC","IL","XD","XM","DM",
    "VV","DD","LL","LD","LM","VC","VM","VD","VL","LC","VX"
]

// MARK: - Symbol Chip

private struct SymbolChipView: View {
    let symbol: String
    let value:  Int
    let accent: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(symbol)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(accent)
            Text(value.formatted())
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.primary.opacity(0.60))
        }
        .frame(minWidth: 44)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Main View

struct DecimalRomanNumbersView: View {

    @State private var decimalText: String = ""
    @State private var romanText:   String = ""
    @State private var errorMsg:    String = ""
    @State private var decimalError: String = ""
    @FocusState private var focused: Field?

    private enum Field: Hashable { case decimal, roman }

    private let gold    = Color(red: 1.00, green: 0.82, blue: 0.22)
    private let crimson = Color(red: 0.95, green: 0.38, blue: 0.22)

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        conversionSection
                        if !errorMsg.isEmpty || !decimalError.isEmpty {
                            errorCard
                        }
                        referenceCard
                        rulesCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .onTapGesture { focused = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Roman Numbers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                Color(red: 0.22, green: 0.05, blue: 0.04),
                Color(red: 0.28, green: 0.08, blue: 0.05),
                Color(red: 0.20, green: 0.05, blue: 0.06),
                Color(red: 0.25, green: 0.06, blue: 0.05),
                Color(red: 0.34, green: 0.10, blue: 0.06),
                Color(red: 0.22, green: 0.06, blue: 0.07),
                Color(red: 0.16, green: 0.04, blue: 0.03),
                Color(red: 0.22, green: 0.07, blue: 0.05),
                Color(red: 0.17, green: 0.04, blue: 0.05)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.14))
                    .frame(width: 50, height: 50)
                Text("Ⅻ")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [gold, crimson],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Roman Number Converter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Bidirectional conversion — range I (1) to MMMCMXCIX (3999)")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Conversion Section

    private var conversionSection: some View {
        HStack(spacing: 12) {
            // Decimal field
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "number")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(gold.opacity(0.80))
                    Text("Decimal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(gold.opacity(0.80))
                }
                TextField("42", text: $decimalText)
                    .keyboardType(.numberPad)
                    .focused($focused, equals: .decimal)
                    .font(.system(size: 34, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(gold)
                    .minimumScaleFactor(0.5)
                    .onChange(of: decimalText) { _, new in
                        guard focused == .decimal else { return }
                        updateFromDecimal(new)
                    }
                Text("1 – 3999")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.30))
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glassEffect(
                focused == .decimal
                    ? .regular.tint(Color(red: 0.22, green: 0.14, blue: 0.02))
                    : .regular,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .animation(.spring(response: 0.25), value: focused == .decimal)

            // Swap arrow
            VStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.40))
            }
            .frame(width: 20)

            // Roman field
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Text("Ⅻ")
                        .font(.system(size: 11, weight: .black, design: .serif))
                        .foregroundStyle(crimson.opacity(0.88))
                    Text("Roman")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(crimson.opacity(0.88))
                }
                TextField("XLII", text: $romanText)
                    .focused($focused, equals: .roman)
                    .font(.system(size: 28, weight: .black, design: .serif).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .tint(crimson)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .minimumScaleFactor(0.5)
                    .onChange(of: romanText) { _, new in
                        guard focused == .roman else { return }
                        updateFromRoman(new)
                    }
                Text("I V X L C D M")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.30))
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glassEffect(
                focused == .roman
                    ? .regular.tint(Color(red: 0.22, green: 0.05, blue: 0.03))
                    : .regular,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .animation(.spring(response: 0.25), value: focused == .roman)
        }
    }

    // MARK: Error Card

    private var errorCard: some View {
        let msg = errorMsg.isEmpty ? decimalError : errorMsg
        return HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.10))
                .font(.system(size: 16))
            Text(msg)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .glassEffect(
            .regular.tint(Color(red: 0.22, green: 0.10, blue: 0.02)),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: msg)
    }

    // MARK: Reference Card

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption.weight(.semibold))
                Text("Symbol Reference")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))

            // Symbols grid (4 + 3)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(romanSymbols.prefix(4), id: \.symbol) { sym in
                        SymbolChipView(symbol: sym.symbol, value: sym.value, accent: gold)
                        if sym.symbol != romanSymbols[3].symbol { Spacer(minLength: 0) }
                    }
                }
                HStack(spacing: 8) {
                    ForEach(romanSymbols.suffix(3), id: \.symbol) { sym in
                        SymbolChipView(symbol: sym.symbol, value: sym.value, accent: gold)
                        if sym.symbol != romanSymbols.last!.symbol { Spacer(minLength: 0) }
                    }
                    Spacer()
                }
            }

            Divider().overlay(Color.primary.opacity(0.10))

            // Subtractive pairs
            HStack(spacing: 5) {
                Image(systemName: "minus.circle")
                    .font(.caption2.weight(.semibold))
                Text("Subtractive pairs:")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.42))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 6) {
                ForEach(subtractivePairs, id: \.roman) { pair in
                    HStack(spacing: 4) {
                        Text(pair.roman)
                            .font(.system(size: 13, weight: .black, design: .serif))
                            .foregroundStyle(crimson.opacity(0.90))
                        Text("=")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.35))
                        Text(pair.value.formatted())
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(gold.opacity(0.80))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Rules Card

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.caption.weight(.semibold))
                Text("Rules")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))

            let rules: [String] = [
                "Symbols are written largest to smallest, left to right",
                "Max. 3 identical consecutive symbols (M, C, X, I)",
                "D, L, V never repeat — only one per numeral",
                "I before V or X subtracts (IV=4, IX=9)",
                "X before L or C subtracts (XL=40, XC=90)",
                "C before D or M subtracts (CD=400, CM=900)",
                "Valid range: 1 (I) to 3999 (MMMCMXCIX)",
            ]

            VStack(alignment: .leading, spacing: 7) {
                ForEach(rules, id: \.self) { rule in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(gold.opacity(0.55))
                        Text(LocalizedStringKey(rule))
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Conversion Logic

    private func updateFromDecimal(_ text: String) {
        let filtered = text.filter { $0.isNumber }
        if filtered != text { decimalText = filtered }
        errorMsg = ""
        guard !filtered.isEmpty else {
            romanText = ""; decimalError = ""; return
        }
        guard let n = Int(filtered) else {
            decimalError = "Invalid number"; return
        }
        guard n >= 1 && n <= 3999 else {
            decimalError = "Value must be between 1 and 3999"
            romanText = ""; return
        }
        decimalError = ""
        romanText = ConvertNumbers(decimal: n).decimalToRoman
    }

    private func updateFromRoman(_ raw: String) {
        decimalError = ""
        let upper = raw.uppercased()

        // Re-uppercase (filter to valid chars)
        let valid   = CharacterSet(charactersIn: "IVXLCDM")
        let cleaned = upper.filter { String($0).unicodeScalars.allSatisfy { valid.contains($0) } }
        if cleaned != raw { romanText = cleaned; return }

        // Check 4+ identical consecutive
        var chars = Array(cleaned)
        let count = chars.count
        if count >= 4 {
            if chars[count-4] == chars[count-3] &&
               chars[count-3] == chars[count-2] &&
               chars[count-2] == chars[count-1] {
                let ch = String(chars[count-4])
                errorMsg = String(format: "More than three %@ not allowed", ch)
                chars.removeLast()
                romanText = String(chars); return
            }
        }

        // Check invalid pairs
        if count >= 2 {
            let pair = String([chars[count-2], chars[count-1]])
            if invalidPairs.contains(pair) {
                errorMsg = String(format: "%@ is not allowed", pair)
                chars.removeLast()
                romanText = String(chars); return
            }
        }

        errorMsg = ""
        if !cleaned.isEmpty {
            let conv = ConvertNumbers(roman: cleaned)
            let dec  = conv.romanToDecimal
            if dec > 0 { decimalText = String(dec) }
        } else {
            decimalText = ""
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DecimalRomanNumbersView()
    }
}
