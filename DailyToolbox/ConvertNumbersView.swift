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
//  ConvertNumbersView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

// MARK: - Field identity

private enum NumberBase: CaseIterable {
    case decimal, hexadecimal, binary

    var label: LocalizedStringKey {
        switch self {
        case .decimal:     return "Decimal"
        case .hexadecimal: return "Hexadecimal"
        case .binary:      return "Binary"
        }
    }

    var shortLabel: LocalizedStringKey {
        switch self {
        case .decimal:     return "Base 10"
        case .hexadecimal: return "Base 16"
        case .binary:      return "Base 2"
        }
    }

    var icon: String {
        switch self {
        case .decimal:     return "number"
        case .hexadecimal: return "hexagon"
        case .binary:      return "square.grid.3x1.below.line.grid.1x2"
        }
    }

    var placeholder: String {
        switch self {
        case .decimal:     return "0"
        case .hexadecimal: return "0"
        case .binary:      return "0"
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .decimal:     return .numberPad
        case .hexadecimal: return .asciiCapable
        case .binary:      return .numberPad
        }
    }

    var accentColor: Color {
        switch self {
        case .decimal:     return Color(red: 1.00, green: 0.78, blue: 0.20)
        case .hexadecimal: return Color(red: 0.75, green: 0.45, blue: 1.00)
        case .binary:      return Color(red: 0.20, green: 0.90, blue: 0.70)
        }
    }
}

// MARK: - Bit Visualization

private struct BitGridView: View {
    let decimal: Int

    private var bitWidth: Int {
        switch decimal {
        case 0..<256:       return 8
        case 256..<65_536:  return 16
        default:            return 32
        }
    }

    private var bits: [Bool] {
        (0..<bitWidth).reversed().map { (decimal >> $0) & 1 == 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row label + bit count
            HStack {
                Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.90, blue: 0.70).opacity(0.80))
                Text("Bit Pattern")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.65))
                Spacer()
                Text("\(bitWidth)-bit")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.45))
            }

            // Bits grouped into nibbles (4 bits), bytes separated by slightly more space
            let nibbles = bits.chunked(into: 4)
            HStack(spacing: 6) {
                ForEach(Array(nibbles.enumerated()), id: \.offset) { nibbleIdx, nibble in
                    // Byte separator gap
                    if nibbleIdx > 0 && nibbleIdx % 2 == 0 {
                        Divider()
                            .frame(width: 1, height: 28)
                            .overlay(Color.primary.opacity(0.18))
                    }
                    HStack(spacing: 3) {
                        ForEach(Array(nibble.enumerated()), id: \.offset) { _, isOn in
                            bitCell(isOn: isOn)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Nibble hex labels (one label per nibble, showing its hex digit)
            HStack(spacing: 6) {
                ForEach(Array(nibbles.enumerated()), id: \.offset) { nibbleIdx, nibble in
                    if nibbleIdx > 0 && nibbleIdx % 2 == 0 {
                        Spacer().frame(width: 1)
                    }
                    let nibbleVal = nibble.reduce(0) { ($0 << 1) | ($1 ? 1 : 0) }
                    Text(String(nibbleVal, radix: 16).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.75, green: 0.45, blue: 1.00).opacity(0.70))
                        .frame(width: 4 * 22 + 3 * 3, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func bitCell(isOn: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isOn
                    ? Color(red: 0.20, green: 0.90, blue: 0.70).opacity(0.22)
                    : Color.primary.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(
                            isOn
                                ? Color(red: 0.20, green: 0.90, blue: 0.70).opacity(0.55)
                                : Color.primary.opacity(0.10),
                            lineWidth: 1
                        )
                }
            Text(isOn ? "1" : "0")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isOn
                    ? Color(red: 0.20, green: 0.90, blue: 0.70)
                    : Color.primary.opacity(0.22))
        }
        .frame(width: 22, height: 26)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
    }
}

// Array chunked helper
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Main View

struct ConvertNumbersView: View {

    @State private var decimalText: String = ""
    @State private var hexText:     String = ""
    @State private var binaryText:  String = ""
    @FocusState private var focused: NumberBase?

    // MARK: Helpers

    private var decimalValue: Int? {
        decimalText.isEmpty ? nil : Int(decimalText)
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            decimalText = ""; hexText = ""; binaryText = ""
        }
    }

    // MARK: - Conversion

    private func convert(from base: NumberBase) {
        switch base {
        case .decimal:
            guard let d = Int(decimalText), !decimalText.isEmpty else {
                hexText = ""; binaryText = ""; return
            }
            withAnimation(.spring(response: 0.28)) {
                hexText    = String(d, radix: 16).uppercased()
                binaryText = String(d, radix: 2)
            }

        case .hexadecimal:
            let upper = hexText.uppercased()
            guard !hexText.isEmpty, let d = Int(upper, radix: 16) else {
                decimalText = ""; binaryText = ""; return
            }
            withAnimation(.spring(response: 0.28)) {
                decimalText = String(d)
                binaryText  = String(d, radix: 2)
            }

        case .binary:
            guard !binaryText.isEmpty, let d = Int(binaryText, radix: 2) else {
                decimalText = ""; hexText = ""; return
            }
            withAnimation(.spring(response: 0.28)) {
                decimalText = String(d)
                hexText     = String(d, radix: 16).uppercased()
            }
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        inputCard(base: .decimal,     text: $decimalText)
                        inputCard(base: .hexadecimal, text: $hexText)
                        inputCard(base: .binary,      text: $binaryText)
                        if let d = decimalValue {
                            bitCard(decimal: d)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .onTapGesture { focused = nil }
        }
        .navigationTitle("Convert Numbers")
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
                Color(red: 0.02, green: 0.08, blue: 0.24),
                Color(red: 0.04, green: 0.14, blue: 0.32),
                Color(red: 0.02, green: 0.10, blue: 0.28),
                Color(red: 0.03, green: 0.11, blue: 0.28),
                Color(red: 0.06, green: 0.18, blue: 0.38),
                Color(red: 0.03, green: 0.13, blue: 0.30),
                Color(red: 0.02, green: 0.06, blue: 0.20),
                Color(red: 0.04, green: 0.12, blue: 0.28),
                Color(red: 0.03, green: 0.09, blue: 0.24)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.20, green: 0.90, blue: 0.70).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "number.square.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.90, blue: 0.70),
                                Color(red: 0.75, green: 0.45, blue: 1.00)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Number Converter")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Enter any base — Decimal, Hex, or Binary.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.60))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.70))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Input Card

    @ViewBuilder
    private func inputCard(base: NumberBase, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(base.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: base.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(base.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(base.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(base.accentColor.opacity(0.85))
                    Text(base.shortLabel)
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.30))
                }
                TextField(base.placeholder, text: text)
                    .keyboardType(base.keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($focused, equals: base)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.primary)
                    .tint(base.accentColor)
                    .onChange(of: text.wrappedValue) { _, newVal in
                        let filtered = filterInput(newVal, for: base)
                        if filtered != text.wrappedValue { text.wrappedValue = filtered }
                        convert(from: base)
                    }
            }

            Spacer(minLength: 0)

            // Copy button
            if !text.wrappedValue.isEmpty {
                Button {
                    UIPasteboard.general.string = text.wrappedValue
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.50))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Bit Pattern Card

    @ViewBuilder
    private func bitCard(decimal d: Int) -> some View {
        VStack {
            BitGridView(decimal: d)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.tint(Color(red: 0.05, green: 0.25, blue: 0.20)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: d)
    }

    // MARK: - Input Filtering

    private func filterInput(_ input: String, for base: NumberBase) -> String {
        switch base {
        case .decimal:
            return input.filter { $0.isNumber }

        case .hexadecimal:
            let upper = input.uppercased()
            return upper.filter { $0.isHexDigit }

        case .binary:
            return input.filter { $0 == "0" || $0 == "1" }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ConvertNumbersView()
    }
}
