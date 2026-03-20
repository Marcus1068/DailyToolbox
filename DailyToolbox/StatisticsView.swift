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
//  StatisticsView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Main View

struct StatisticsView: View {

    @Environment(\.colorScheme) private var colorScheme
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    // MARK: Adaptive accent colors

    private var tealAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.92, blue: 0.76)
            : Color(red: 0.00, green: 0.54, blue: 0.46)
    }
    private var mintAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.00, green: 0.80, blue: 0.65)
            : Color(red: 0.00, green: 0.46, blue: 0.40)
    }
    private var glassTint: Color {
        colorScheme == .dark
            ? Color(red: 0.03, green: 0.20, blue: 0.18)
            : Color(red: 0.82, green: 0.96, blue: 0.93)
    }

    // MARK: Computed

    private var numbers: [Double] { parseInput(inputText) }
    private var stats: Statistics { Statistics(values: numbers) }

    private func parseInput(_ text: String) -> [Double] {
        text
            .components(separatedBy: CharacterSet(charactersIn: " ,;\n\t"))
            .compactMap { token -> Double? in
                let s = token.trimmingCharacters(in: .whitespaces)
                guard !s.isEmpty else { return nil }
                return Double(s)
            }
    }

    private func fmt(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...4)))
    }

    // Normalized mean position between min and max for the ring.
    private var normalizedMean: Double {
        guard let m = stats.mean,
              let lo = stats.minimum,
              let hi = stats.maximum,
              hi != lo
        else { return stats.count > 0 ? 1.0 : 0.0 }
        return min(1.0, max(0.0, (m - lo) / (hi - lo)))
    }

    private var countBadgeText: LocalizedStringKey {
        stats.count == 1 ? "1 value" : "\(stats.count) values"
    }

    private var modeLabel: LocalizedStringKey {
        stats.modes.count > 1 ? "Modes" : "Mode"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        inputCard
                        if stats.count >= 1 {
                            featuredCard
                            statsGridCard
                            if !stats.modes.isEmpty {
                                modeCard
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                    .animation(.spring(response: 0.4), value: stats.count)
                }
            }
        }
        .navigationTitle("Statistics")
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
                Color(red: 0.02, green: 0.14, blue: 0.14),
                Color(red: 0.03, green: 0.18, blue: 0.16),
                Color(red: 0.02, green: 0.12, blue: 0.14),
                Color(red: 0.03, green: 0.16, blue: 0.16),
                Color(red: 0.04, green: 0.22, blue: 0.20),
                Color(red: 0.02, green: 0.14, blue: 0.16),
                Color(red: 0.01, green: 0.08, blue: 0.10),
                Color(red: 0.02, green: 0.12, blue: 0.12),
                Color(red: 0.02, green: 0.10, blue: 0.11)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tealAccent.opacity(0.16))
                    .frame(width: 50, height: 50)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tealAccent, mintAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Statistics")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Mean · Median · Std Dev · More")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Input

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.caption.weight(.semibold))
                Text("Numbers")
                    .font(.caption.weight(.semibold))
                Spacer()
                if stats.count > 0 {
                    Text(countBadgeText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tealAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tealAccent.opacity(0.15), in: Capsule())
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: stats.count)
                }
            }
            .foregroundStyle(Color.primary.opacity(0.50))

            TextField(
                "1 2 3 5 8 13  —  spaces, commas, or new lines; use . for decimals",
                text: $inputText,
                axis: .vertical
            )
            .lineLimit(3...)
            .keyboardType(.numbersAndPunctuation)
            .font(.body.monospaced())
            .foregroundStyle(Color.primary)
            .focused($isInputFocused)

            if !inputText.isEmpty {
                HStack {
                    Spacer()
                    Button("Clear", action: clearInput)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.55))
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Featured card (mean + ring)

    private var featuredCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: normalizedMean)
                    .stroke(
                        AngularGradient(
                            colors: [tealAccent, mintAccent, mintAccent],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: normalizedMean)
                    .shadow(color: tealAccent.opacity(0.35), radius: 5)
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                if let m = stats.mean {
                    Text(fmt(m))
                        .font(.system(size: 40, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(tealAccent)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35), value: m)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Text("mean")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.60))

                HStack(spacing: 12) {
                    if let med = stats.median {
                        Label {
                            Text("median \(fmt(med))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.primary.opacity(0.55))
                        } icon: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                                .foregroundStyle(mintAccent.opacity(0.80))
                        }
                    }
                    Label {
                        Text("\(stats.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.primary.opacity(0.55))
                    } icon: {
                        Image(systemName: "number")
                            .font(.caption2)
                            .foregroundStyle(mintAccent.opacity(0.80))
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(glassTint), in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.3), value: stats.mean)
    }

    // MARK: Stats grid

    private var statsGridCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tablecells")
                    .font(.caption.weight(.semibold))
                Text("Descriptive Statistics")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile(label: "Sum",         icon: "sum",                    value: stats.sum)
                statTile(label: "Range",       icon: "arrow.left.and.right",   value: stats.range)
                statTile(label: "Minimum",     icon: "arrow.down.circle",      value: stats.minimum)
                statTile(label: "Maximum",     icon: "arrow.up.circle",        value: stats.maximum)
                statTile(label: "Std Dev σ",   icon: "waveform",               value: stats.standardDeviation)
                statTile(label: "Variance σ²", icon: "chart.bar.xaxis",        value: stats.variance)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func statTile(label: LocalizedStringKey, icon: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tealAccent.opacity(0.80))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.50))
            }
            if let v = value {
                Text(fmt(v))
                    .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(tealAccent)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .animation(.spring(response: 0.3), value: v)
            } else {
                Text("—")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.25))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Mode card

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.caption.weight(.semibold))
                Text(modeLabel)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))

            HStack(spacing: 8) {
                ForEach(stats.modes, id: \.self) { mode in
                    Text(fmt(mode))
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(tealAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tealAccent.opacity(0.12), in: Capsule())
                }
                Spacer()
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Actions

    private func clearInput() {
        withAnimation(.spring(response: 0.3)) {
            inputText = ""
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatisticsView()
    }
}
