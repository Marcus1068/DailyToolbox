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
//  OhmsLawView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Field Identity

private enum OhmsField: String, CaseIterable, Hashable {
    case voltage    = "Voltage"
    case current    = "Current"
    case resistance = "Resistance"
    case power      = "Power"

    var symbol: String {
        switch self {
        case .voltage:    return "V"
        case .current:    return "I"
        case .resistance: return "R"
        case .power:      return "P"
        }
    }

    var unit: String {
        switch self {
        case .voltage:    return "V"
        case .current:    return "A"
        case .resistance: return "Ω"
        case .power:      return "W"
        }
    }

    var icon: String {
        switch self {
        case .voltage:    return "bolt.fill"
        case .current:    return "arrow.right.circle.fill"
        case .resistance: return "waveform.path.ecg"
        case .power:      return "lightbulb.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .voltage:    return Color(red: 1.00, green: 0.85, blue: 0.35)
        case .current:    return Color(red: 0.55, green: 0.85, blue: 1.00)
        case .resistance: return Color(red: 1.00, green: 0.55, blue: 0.35)
        case .power:      return Color(red: 0.65, green: 1.00, blue: 0.45)
        }
    }
}

// MARK: - Solver

private func solve(f1: OhmsField, v1: Double, f2: OhmsField, v2: Double) -> [OhmsField: Double] {
    var out: [OhmsField: Double] = [f1: v1, f2: v2]
    let pair = Set([f1, f2])

    if pair == [.voltage, .current] {
        out[.resistance] = v1 / v2
        out[.power]      = v1 * v2
    } else if pair == [.voltage, .resistance] {
        out[.current] = v1 / v2
        out[.power]   = v1 * v1 / v2
    } else if pair == [.voltage, .power] {
        out[.current]    = v2 / v1
        out[.resistance] = v1 * v1 / v2
    } else if pair == [.current, .resistance] {
        out[.voltage] = v1 * v2
        out[.power]   = v1 * v1 * v2
    } else if pair == [.current, .power] {
        out[.voltage]    = v2 / v1
        out[.resistance] = v2 / (v1 * v1)
    } else if pair == [.resistance, .power] {
        out[.voltage]  = sqrt(v1 * v2)
        out[.current]  = sqrt(v2 / v1)
    }
    return out
}

// MARK: - Main View

struct OhmsLawView: View {

    @State private var texts: [OhmsField: String] = [:]
    @State private var computed: Set<OhmsField> = []
    @State private var inputQueue: [OhmsField] = []   // last 2 user-typed fields, newest first

    @FocusState private var focused: OhmsField?

    private let fields = OhmsField.allCases

    // MARK: Input handling

    private func fieldChanged(_ field: OhmsField) {
        guard focused == field else { return }

        // Update input queue
        inputQueue.removeAll { $0 == field }
        inputQueue.insert(field, at: 0)
        if inputQueue.count > 2 {
            let evicted = inputQueue.removeLast()
            texts[evicted] = ""
            computed.remove(evicted)
        }
        computed.remove(field)

        // Try to solve
        guard inputQueue.count == 2,
              let v1 = Double(texts[inputQueue[0]]?.replacingOccurrences(of: ",", with: ".") ?? ""),
              let v2 = Double(texts[inputQueue[1]]?.replacingOccurrences(of: ",", with: ".") ?? ""),
              v1 > 0, v2 > 0
        else {
            // Clear computed outputs
            for f in OhmsField.allCases where !inputQueue.contains(f) {
                if computed.contains(f) {
                    texts[f] = ""
                    computed.remove(f)
                }
            }
            return
        }

        let result = solve(f1: inputQueue[0], v1: v1, f2: inputQueue[1], v2: v2)
        withAnimation(.spring(response: 0.3)) {
            for (k, v) in result where !inputQueue.contains(k) {
                texts[k] = format(v)
                computed.insert(k)
            }
        }
    }

    private func format(_ v: Double) -> String {
        if abs(v) == 0 { return "0" }
        if abs(v) >= 1e6 || (abs(v) < 0.001 && abs(v) > 0) {
            return String(format: "%.4e", v)
        }
        return String(format: "%.6g", v)
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            texts = [:]
            computed = []
            inputQueue = []
        }
        focused = nil
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { fieldGrid }
                    GlassEffectContainer { formulaCard }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onTapGesture { focused = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Ohm's Law")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0,0.0],[0.5,0.0],[1.0,0.0],
                [0.0,0.5],[0.5,0.5],[1.0,0.5],
                [0.0,1.0],[0.5,1.0],[1.0,1.0]
            ],
            colors: [
                Color(red:0.18,green:0.10,blue:0.03), Color(red:0.22,green:0.13,blue:0.03), Color(red:0.18,green:0.10,blue:0.03),
                Color(red:0.22,green:0.13,blue:0.04), Color(red:0.28,green:0.16,blue:0.04), Color(red:0.22,green:0.13,blue:0.03),
                Color(red:0.16,green:0.09,blue:0.02), Color(red:0.20,green:0.12,blue:0.03), Color(red:0.16,green:0.09,blue:0.02)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [
                        Color(red:1.00,green:0.75,blue:0.20),
                        Color(red:0.90,green:0.45,blue:0.10)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "bolt.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.primary)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Ohm's Law Calculator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Enter any 2 values to solve")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.75))
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Field Grid

    private var fieldGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(OhmsField.allCases, id: \.self) { field in
                fieldCard(field)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func fieldCard(_ field: OhmsField) -> some View {
        let isComputed = computed.contains(field)
        let accent = field.accentColor

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: field.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                Text(LocalizedStringKey(field.rawValue))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text(field.unit)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent.opacity(0.70))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(accent.opacity(0.15))
                    )
            }

            TextField("—", text: Binding(
                get: { texts[field] ?? "" },
                set: { texts[field] = $0 }
            ))
            .keyboardType(.decimalPad)
            .focused($focused, equals: field)
            .font(.title2.weight(.bold).monospacedDigit())
            .foregroundStyle(isComputed ? accent : Color.primary)
            .tint(accent)
            .onChange(of: texts[field] ?? "") { _, _ in fieldChanged(field) }

            Text(field.symbol)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.primary.opacity(0.30))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isComputed ? accent.opacity(0.08) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isComputed ? accent.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Formula Card

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Formulas")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.primary.opacity(0.50))

            VStack(alignment: .leading, spacing: 6) {
                formulaRow("V = I × R")
                formulaRow("P = V × I")
                formulaRow("I = V ÷ R")
                formulaRow("P = I² × R")
                formulaRow("R = V ÷ I")
                formulaRow("P = V² ÷ R")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private func formulaRow(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Color.primary.opacity(0.50))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OhmsLawView()
    }
}
