/*
 BenchmarkView.swift
 DailyToolbox

 SwiftUI replacement for BenchmarkViewController / BenchmarkPageViewController.
 Consolidates all benchmark functionality into one liquid-glass screen.
*/

import SwiftUI

// MARK: - Benchmark Runner

@Observable @MainActor
final class BenchmarkRunner {

    enum BenchType: String, CaseIterable, Identifiable {
        case arc4     = "arc4random"
        case swift    = "Swift.random"
        case addition = "Addition"
        case strings  = "Strings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .arc4:     "dice.fill"
            case .swift:    "bolt.fill"
            case .addition: "plus.circle.fill"
            case .strings:  "textformat.characters"
            }
        }

        var accentColor: Color {
            switch self {
            case .arc4:     Color(red: 0.00, green: 0.85, blue: 1.00)  // electric cyan
            case .swift:    Color(red: 0.55, green: 0.25, blue: 1.00)  // violet
            case .addition: Color(red: 0.00, green: 0.90, blue: 0.50)  // neon green
            case .strings:  Color(red: 1.00, green: 0.60, blue: 0.00)  // amber
            }
        }
    }

    let ranges = [10_000, 50_000, 200_000, 500_000]
    var selectedRange: [BenchType: Int] = [
        .arc4: 50_000, .swift: 50_000, .addition: 50_000, .strings: 0
    ]
    var repeatCount: Int = 1
    var results: [BenchType: Double] = [:]
    var isRunning: BenchType?
    var isRunningAll = false

    let deviceName = DeviceInfo.getDeviceName()
    let osVersion  = DeviceInfo.getOSVersion()

    // Run one benchmark type on a detached background task
    func run(_ type: BenchType) async {
        guard isRunning == nil else { return }
        isRunning = type
        let range = selectedRange[type] ?? 50_000
        let reps  = repeatCount

        let elapsed: Double = await Task.detached(priority: .userInitiated) {
            var last: Double = 0
            for _ in 0..<reps {
                let start = Date()
                switch type {
                case .arc4:
                    var sum = 0
                    for _ in 0..<range { sum += Int.random(in: 0..<100) }
                case .swift:
                    var sum = 0
                    for _ in 0..<range { sum += Int.random(in: 0..<100) }
                case .addition:
                    var sum = 0.0
                    for _ in 0..<range { sum += Double.random(in: 0..<1) }
                case .strings:
                    var s = "Benchmark test with Swift"
                    for _ in 0..<25 { s += s }
                }
                last = Date().timeIntervalSince(start)
            }
            return last
        }.value

        results[type] = elapsed
        isRunning = nil
    }

    func runAll() async {
        isRunningAll = true
        for type in BenchType.allCases {
            await run(type)
        }
        isRunningAll = false
    }

    // Simple composite score (lower total time → higher score, max ~1000)
    var score: Int? {
        guard results.count == BenchType.allCases.count else { return nil }
        let total = BenchType.allCases.compactMap { results[$0] }.reduce(0, +)
        return max(0, Int((2.0 - min(total, 2.0)) / 2.0 * 1000))
    }
}

// MARK: - BenchmarkView

struct BenchmarkView: View {

    @State private var runner = BenchmarkRunner()

    var body: some View {
        ZStack {
            // Deep-space MeshGradient background
            MeshGradient(width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.14),
                    Color(red: 0.04, green: 0.01, blue: 0.20),
                    Color(red: 0.01, green: 0.03, blue: 0.16),
                    Color(red: 0.03, green: 0.02, blue: 0.22),
                    Color(red: 0.07, green: 0.02, blue: 0.30),
                    Color(red: 0.02, green: 0.04, blue: 0.24),
                    Color(red: 0.01, green: 0.05, blue: 0.13),
                    Color(red: 0.03, green: 0.08, blue: 0.20),
                    Color(red: 0.01, green: 0.04, blue: 0.15)
                ]
            )
            .ignoresSafeArea()

            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 20) {
                        deviceCard
                        benchmarkGrid
                        repeatRow
                        runAllButton
                        if !runner.results.isEmpty {
                            timingChart
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Benchmark")
    }

    // MARK: - Device Info Card

    private var deviceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse, isActive: runner.isRunning != nil || runner.isRunningAll)

            VStack(alignment: .leading, spacing: 2) {
                Text(runner.deviceName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("iOS \(runner.osVersion)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            if let score = runner.score {
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("score")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .glassEffect(.regular.tint(Color.cyan.opacity(0.07)),
                     in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(duration: 0.4), value: runner.score)
    }

    // MARK: - 2x2 Benchmark Grid

    private var benchmarkGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(BenchmarkRunner.BenchType.allCases) { type in
                BenchCard(type: type, runner: runner)
            }
        }
    }

    // MARK: - Repeat Row

    private var repeatRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "repeat")
                .foregroundStyle(.white.opacity(0.7))
            Text("Repeat")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Button {
                if runner.repeatCount > 1 { runner.repeatCount -= 1 }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .disabled(runner.repeatCount <= 1)

            Text("\(runner.repeatCount)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 32)
                .animation(.spring(duration: 0.2), value: runner.repeatCount)

            Button {
                if runner.repeatCount < 10 { runner.repeatCount += 1 }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .disabled(runner.repeatCount >= 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Run All Button

    private var runAllButton: some View {
        Button {
            Task { await runner.runAll() }
        } label: {
            HStack(spacing: 10) {
                if runner.isRunningAll {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 17))
                }
                Text(runner.isRunningAll ? "Running\u{2026}" : "Run All Benchmarks")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
        }
        .buttonStyle(.glassProminent)
        .disabled(runner.isRunning != nil || runner.isRunningAll)
    }

    // MARK: - Timing Comparison Chart

    private var timingChart: some View {
        let maxTime = BenchmarkRunner.BenchType.allCases
            .compactMap { runner.results[$0] }
            .max() ?? 1.0

        return VStack(alignment: .leading, spacing: 12) {
            Text("Timing Comparison")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            ForEach(BenchmarkRunner.BenchType.allCases) { type in
                if let t = runner.results[type] {
                    HStack(spacing: 10) {
                        Image(systemName: type.icon)
                            .font(.caption)
                            .foregroundStyle(type.accentColor)
                            .frame(width: 14)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.08))
                                    .frame(height: 10)
                                Capsule()
                                    .fill(type.accentColor.opacity(0.85))
                                    .frame(
                                        width: geo.size.width * CGFloat(t / maxTime),
                                        height: 10
                                    )
                                    .animation(.spring(duration: 0.7), value: t)
                            }
                        }
                        .frame(height: 10)

                        let sText = String(format: "%.3fs", t)
                        Text(sText)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.5), value: runner.results.count)
    }
}

// MARK: - Individual Benchmark Card

private struct BenchCard: View {

    let type: BenchmarkRunner.BenchType
    let runner: BenchmarkRunner

    private let ranges = [10_000, 50_000, 200_000, 500_000]

    var body: some View {
        let isActive = runner.isRunning == type
        let isBusy   = runner.isRunning != nil || runner.isRunningAll
        let result   = runner.results[type]

        VStack(alignment: .leading, spacing: 8) {

            // Icon + spinner
            HStack(alignment: .center) {
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(type.accentColor)
                    .symbolEffect(.pulse, isActive: isActive)
                Spacer()
                if isActive {
                    ProgressView()
                        .tint(type.accentColor)
                        .scaleEffect(0.7)
                }
            }

            // Name
            Text(type.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Range / descriptor
            if type != .strings {
                let currentRange = runner.selectedRange[type] ?? 50_000
                Menu {
                    ForEach(ranges, id: \.self) { r in
                        Button(rangeLabel(r)) {
                            runner.selectedRange[type] = r
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(rangeLabel(currentRange))
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: Capsule())
                }
            } else {
                Text("25\u{00D7} doubling")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(height: 25, alignment: .center)
            }

            // Result
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                if let t = result {
                    Text(String(format: "%.4f", t))
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(type.accentColor)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.4), value: t)
                    Text("s")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    Text("\u{2014}")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            // Run button
            Button {
                Task { await runner.run(type) }
            } label: {
                Text("Run")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .disabled(isBusy)
        }
        .padding(12)
        .glassEffect(
            .regular.tint(type.accentColor.opacity(0.05)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func rangeLabel(_ n: Int) -> String {
        n >= 1_000 ? "\(n / 1_000)K" : "\(n)"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BenchmarkView()
    }
}
