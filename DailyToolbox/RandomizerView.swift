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
//  RandomizerView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Tab

private enum RandomTab: String, CaseIterable {
    case coin   = "Coin"
    case dice   = "Dice"
    case number = "Number"
    case list   = "List"

    var icon: String {
        switch self {
        case .coin:   return "circle.lefthalf.filled"
        case .dice:   return "dice.fill"
        case .number: return "number"
        case .list:   return "list.bullet"
        }
    }
    var localizedKey: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

// MARK: - Dice type

private enum DieType: Int, CaseIterable {
    case d4 = 4, d6 = 6, d8 = 8, d10 = 10, d12 = 12, d20 = 20
    var label: String { "d\(rawValue)" }
}

// MARK: - View

struct RandomizerView: View {

    @State private var tab: RandomTab = .coin

    // Coin
    @State private var coinResult: Bool? = nil         // true = heads
    @State private var coinSpinning = false
    @State private var coinRotation: Double = 0

    // Dice
    @State private var dieType: DieType = .d6
    @State private var diceResult: Int? = nil
    @State private var diceScale: CGFloat = 1.0
    @State private var diceCount = 1                   // 1–5 dice

    // Number
    @State private var minText = "1"
    @State private var maxText = "100"
    @State private var numberResult: Int? = nil
    @FocusState private var numFocused: Int?

    // List
    @State private var listText = ""
    @State private var listResult: String? = nil
    @FocusState private var listFocused: Bool

    // Shared
    @State private var shakeAngle: Double = 0

    private let accent = Color(red: 1.00, green: 0.65, blue: 0.20)

    // MARK: Body

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                tabBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 14) {
                        switch tab {
                        case .coin:   GlassEffectContainer { coinCard }
                        case .dice:   GlassEffectContainer { diceCard }
                        case .number: GlassEffectContainer { numberCard }
                        case .list:   GlassEffectContainer { listCard }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onTapGesture { numFocused = nil; listFocused = false }
            }
        }
        .navigationTitle("Randomizer")
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
                Color(red:0.16,green:0.08,blue:0.02), Color(red:0.20,green:0.10,blue:0.02), Color(red:0.16,green:0.08,blue:0.02),
                Color(red:0.20,green:0.10,blue:0.02), Color(red:0.26,green:0.13,blue:0.03), Color(red:0.20,green:0.10,blue:0.02),
                Color(red:0.14,green:0.07,blue:0.02), Color(red:0.18,green:0.09,blue:0.02), Color(red:0.14,green:0.07,blue:0.02)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(RandomTab.allCases, id: \.self) { t in
                let sel = tab == t
                Button { withAnimation(.spring(response: 0.3)) { tab = t } } label: {
                    HStack(spacing: 6) {
                        Image(systemName: t.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(t.localizedKey)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(sel ? accent : Color.primary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - COIN

    private var coinCard: some View {
        VStack(spacing: 32) {
            // Coin visual
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: coinResult == nil
                            ? [Color(red:0.55,green:0.55,blue:0.60), Color(red:0.35,green:0.35,blue:0.40)]
                            : coinResult! == true
                                ? [Color(red:1.00,green:0.85,blue:0.25), Color(red:0.85,green:0.65,blue:0.10)]
                                : [Color(red:0.70,green:0.70,blue:0.75), Color(red:0.50,green:0.50,blue:0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.35), radius: 12)
                    .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))

                if let heads = coinResult {
                    Text(heads ? "H" : "T")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
            }
            .frame(height: 160)

            Text(coinResult == nil ? "Tap to flip"
                 : coinResult! ? "Heads!" : "Tails!")
                .font(.title2.weight(.bold))
                .foregroundStyle(coinResult == nil ? Color.primary.opacity(0.40) : accent)

            Button { flipCoin() } label: {
                Label("Flip Coin", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent))
            }
            .buttonStyle(.plain)
            .disabled(coinSpinning)
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func flipCoin() {
        guard !coinSpinning else { return }
        coinSpinning = true
        let result = Bool.random()
        withAnimation(.easeIn(duration: 0.15)) { coinRotation = 90 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            coinResult = result
            withAnimation(.easeOut(duration: 0.15)) { coinRotation = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                coinSpinning = false
            }
        }
    }

    // MARK: - DICE

    private var diceCard: some View {
        VStack(spacing: 20) {
            // Die type selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DieType.allCases, id: \.self) { d in
                        let sel = dieType == d
                        Button {
                            withAnimation(.spring(response: 0.25)) { dieType = d; diceResult = nil }
                        } label: {
                            Text(d.label)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(sel ? accent : Color.primary.opacity(0.10),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            // Count stepper
            HStack {
                Text("Number of dice")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.60))
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        if diceCount > 1 { withAnimation { diceCount -= 1; diceResult = nil } }
                    } label: {
                        Image(systemName: "minus").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(diceCount > 1 ? accent : Color.primary.opacity(0.25))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    Text("\(diceCount)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primary)
                        .frame(minWidth: 28)
                    Button {
                        if diceCount < 5 { withAnimation { diceCount += 1; diceResult = nil } }
                    } label: {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(diceCount < 5 ? accent : Color.primary.opacity(0.25))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Result
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 110)

                if let result = diceResult {
                    VStack(spacing: 4) {
                        Text("\(result)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(accent)
                            .scaleEffect(diceScale)
                        if diceCount > 1 {
                            Text("total of \(diceCount) × \(dieType.label)")
                                .font(.caption).foregroundStyle(Color.primary.opacity(0.45))
                        }
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "dice").font(.largeTitle).foregroundStyle(Color.primary.opacity(0.20))
                        Text("Roll to see result").font(.caption).foregroundStyle(Color.primary.opacity(0.30))
                    }
                }
            }

            Button { rollDice() } label: {
                Label("Roll \(diceCount) × \(dieType.label)", systemImage: "dice.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func rollDice() {
        let total = (0..<diceCount).reduce(0) { acc, _ in acc + Int.random(in: 1...dieType.rawValue) }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            diceScale = 1.25
            diceResult = total
        }
        withAnimation(.spring(response: 0.3).delay(0.15)) { diceScale = 1.0 }
    }

    // MARK: - NUMBER

    private var numberCard: some View {
        VStack(spacing: 20) {
            // Result hero
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 100)
                if let n = numberResult {
                    Text("\(n)")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("?")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.15))
                }
            }

            HStack(spacing: 14) {
                rangeField(label: "Min", text: $minText, tag: 1)
                Text("–").font(.title2.weight(.light)).foregroundStyle(Color.primary.opacity(0.40))
                rangeField(label: "Max", text: $maxText, tag: 2)
            }

            Button { generateNumber() } label: {
                Label("Generate", systemImage: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func rangeField(label: LocalizedStringKey, text: Binding<String>, tag: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(accent.opacity(0.80))
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .focused($numFocused, equals: tag)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.primary).tint(accent)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.07)))
        }
        .frame(maxWidth: .infinity)
    }

    private func generateNumber() {
        numFocused = nil
        let lo = Int(minText) ?? 1
        let hi = Int(maxText) ?? 100
        guard lo <= hi else { return }
        withAnimation(.spring(response: 0.3)) { numberResult = Int.random(in: lo...hi) }
    }

    // MARK: - LIST

    private var listCard: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Items (one per line or comma-separated)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent.opacity(0.80))
                TextEditor(text: $listText)
                    .focused($listFocused)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .tint(accent)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.07)))
            }

            if let pick = listResult {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent.opacity(0.15))
                    VStack(spacing: 4) {
                        Text("Selected")
                            .font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
                        Text(pick)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 16)
                }
            }

            Button { pickFromList() } label: {
                Label("Pick Random", systemImage: "hand.point.up.left.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent))
            }
            .buttonStyle(.plain)
            .disabled(listText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func pickFromList() {
        listFocused = false
        let raw = listText
        var items = raw.components(separatedBy: ",").flatMap { $0.components(separatedBy: "\n") }
        items = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !items.isEmpty else { return }
        withAnimation(.spring(response: 0.3)) { listResult = items.randomElement() }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { RandomizerView() }
}
