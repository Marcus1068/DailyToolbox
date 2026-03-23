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
//  BenchmarkView.swift
//  DailyToolbox
//
//  8-benchmark suite: integer math, float math, memory bandwidth,
//  array sort, JSON codec, string processing, SHA-256, LZFSE compression.
//

import SwiftUI
import CryptoKit
import Metal

// MARK: - JSON helper (file-scope: Codable types cannot be defined inside closures)

private struct BenchJSONItem: Codable, Sendable {
    let id: Int
    let label: String
    let value: Double
}

// MARK: - Persisted Run Result

private struct BenchmarkResult: Codable {
    let date:       Date
    let score:      Int
    let timings:    [String: Double]   // BenchType.rawValue → seconds
    let deviceName: String
}

// MARK: - Benchmark Runner

@Observable @MainActor
final class BenchmarkRunner {

    enum BenchType: String, CaseIterable, Identifiable {
        case intArith   = "Integer Math"
        case floatMath  = "Float Math"
        case memory     = "Memory"
        case arraySort  = "Array Sort"
        case jsonCodec  = "JSON Codec"
        case stringProc = "Strings"
        case crypto     = "SHA-256"
        case compress   = "Compression"
        case gpuCompute = "GPU Compute"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .intArith:   return "function"
            case .floatMath:  return "waveform.path"
            case .memory:     return "memorychip"
            case .arraySort:  return "arrow.up.arrow.down"
            case .jsonCodec:  return "doc.badge.arrow.up"
            case .stringProc: return "textformat.characters"
            case .crypto:     return "lock.shield.fill"
            case .compress:   return "arrow.down.left.arrow.up.right"
            case .gpuCompute: return "gpu"
            }
        }

        var accentColor: Color {
            switch self {
            case .intArith:   return Color(red: 0.00, green: 0.85, blue: 1.00)  // cyan
            case .floatMath:  return Color(red: 0.55, green: 0.25, blue: 1.00)  // violet
            case .memory:     return Color(red: 0.00, green: 0.90, blue: 0.50)  // neon green
            case .arraySort:  return Color(red: 1.00, green: 0.60, blue: 0.00)  // amber
            case .jsonCodec:  return Color(red: 0.20, green: 0.70, blue: 1.00)  // sky blue
            case .stringProc: return Color(red: 1.00, green: 0.30, blue: 0.60)  // rose
            case .crypto:     return Color(red: 0.90, green: 0.80, blue: 0.20)  // gold
            case .compress:   return Color(red: 0.40, green: 1.00, blue: 0.60)  // mint
            case .gpuCompute: return Color(red: 0.85, green: 0.25, blue: 0.90)  // purple-pink
            }
        }

        // Iteration or byte counts per selectable tier
        var ranges: [Int] {
            switch self {
            case .intArith:   return [100_000,  500_000, 2_000_000, 5_000_000]
            case .floatMath:  return [100_000,  500_000, 1_000_000, 2_000_000]
            case .memory:     return [100_000,  500_000, 1_000_000, 5_000_000]
            case .arraySort:  return [ 10_000,   50_000,   200_000,   500_000]
            case .jsonCodec:  return [    100,      500,     1_000,     5_000]
            case .stringProc: return [  1_000,    5_000,    20_000,    50_000]
            case .crypto:     return [ 10_240,  102_400,   524_288, 2_097_152]  // 10KB…2MB
            case .compress:   return [ 10_240,  102_400,   524_288, 2_097_152]  // 10KB…2MB
            case .gpuCompute: return [100_000,  500_000, 1_000_000, 4_000_000]
            }
        }

        var defaultRange: Int { ranges[1] }

        func rangeLabel(_ n: Int) -> String {
            switch self {
            case .crypto, .compress:
                if n >= 1_048_576 { return "\(n / 1_048_576) MB" }
                return "\(n / 1_024) KB"
            case .jsonCodec:
                return n >= 1_000 ? "\(n / 1_000)K obj" : "\(n) obj"
            default:
                if n >= 1_000_000 { return "\(n / 1_000_000)M" }
                return "\(n / 1_000)K"
            }
        }
    }

    var selectedRange: [BenchType: Int]
    var repeatCount:   Int = 1
    var results:       [BenchType: Double] = [:]
    var isRunning:     BenchType?
    var isRunningAll   = false

    let deviceName = DeviceInfo.getDeviceName()
    let osVersion  = DeviceInfo.getOSVersion()

    private let resultKey = "benchmark.resultHistory"

    fileprivate var resultHistory: [BenchmarkResult] {
        guard let data = UserDefaults.standard.data(forKey: resultKey) else { return [] }
        return (try? JSONDecoder().decode([BenchmarkResult].self, from: data)) ?? []
    }

    fileprivate var previousResult: BenchmarkResult? {
        resultHistory.dropFirst().first
    }

    private func saveResult() {
        guard let score else { return }
        let timings = Dictionary(
            uniqueKeysWithValues: BenchType.allCases.compactMap { t in
                results[t].map { (t.rawValue, $0) }
            }
        )
        let result = BenchmarkResult(
            date: Date(), score: score, timings: timings, deviceName: deviceName
        )
        var history = resultHistory
        history.insert(result, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: resultKey)
        }
    }

    init() {
        selectedRange = Dictionary(
            uniqueKeysWithValues: BenchType.allCases.map { ($0, $0.defaultRange) }
        )
    }

    // MARK: Run single benchmark

    func run(_ type: BenchType) async {
        guard isRunning == nil else { return }
        isRunning = type
        let range = selectedRange[type] ?? type.defaultRange
        let reps  = repeatCount

        let elapsed: Double = await Task.detached(priority: .userInitiated) {
            var last = 0.0
            for _ in 0..<reps {
                let start = Date()
                var gpuElapsed: Double? = nil
                switch type {

                // 1. Integer Arithmetic — tight multiply / XOR / shift loop
                case .intArith:
                    var x: UInt64 = 1
                    for i in 1...range {
                        x = (x &* UInt64(i &+ 1)) ^ (x >> 3) &+ UInt64(i)
                    }
                    _ = x

                // 2. Float Math — sin + cos + sqrt per iteration (tests FPU/SIMD)
                case .floatMath:
                    var acc = 0.0
                    for i in 0..<range {
                        let d = Double(i) * 0.001
                        acc += sin(d) + cos(d) + sqrt(d + 1.0)
                    }
                    _ = acc

                // 3. Memory Bandwidth — allocate, fill, then sum a large Int array
                case .memory:
                    var arr = [Int](repeating: 0, count: range)
                    for i in 0..<range { arr[i] = i &* 3 &+ 1 }
                    var sum = 0
                    for v in arr { sum = sum &+ v }
                    _ = sum

                // 4. Array Sort — sort N random integers (tests branch predictor + cache)
                case .arraySort:
                    var arr = (0..<range).map { _ in Int.random(in: 0..<1_000_000) }
                    arr.sort()
                    _ = arr.first

                // 5. JSON Codec — encode + decode N lightweight Codable objects
                case .jsonCodec:
                    let items = (0..<range).map {
                        BenchJSONItem(id: $0, label: "item_\($0)", value: Double($0) * 1.618)
                    }
                    let encoder = JSONEncoder()
                    let decoder = JSONDecoder()
                    if let data = try? encoder.encode(items) {
                        _ = try? decoder.decode([BenchJSONItem].self, from: data)
                    }

                // 6. String Processing — contains + split + joined per iteration
                case .stringProc:
                    let base = "The quick brown fox jumps over the lazy dog. Swift is powerful and safe."
                    var found = 0
                    for _ in 0..<range {
                        if base.contains("fox") { found &+= 1 }
                        let parts = base.split(separator: " ")
                        _ = parts.joined(separator: "-")
                    }
                    _ = found

                // 7. SHA-256 — hash N bytes via CryptoKit (tests hardware crypto engine)
                case .crypto:
                    let data = Data(repeating: 0x5A, count: range)
                    _ = SHA256.hash(data: data)

                // 8. Compression — LZFSE compress + decompress N bytes
                case .compress:
                    let source = Data((0..<range).map { UInt8($0 & 0xFF) })
                    if let compressed = try? (source as NSData).compressed(using: .lzfse) as Data {
                        _ = try? (compressed as NSData).decompressed(using: .lzfse)
                    }

                // 9. GPU Compute — Metal sin/cos kernel on large float arrays
                case .gpuCompute:
                    let count = range
                    let floatSize = count * MemoryLayout<Float>.stride
                    guard let device = MTLCreateSystemDefaultDevice(),
                          let queue = device.makeCommandQueue() else {
                        gpuElapsed = -1.0
                        break
                    }
                    let shaderSrc = """
                    #include <metal_stdlib>
                    using namespace metal;
                    kernel void sinCosAdd(
                        device const float* a [[ buffer(0) ]],
                        device const float* b [[ buffer(1) ]],
                        device float* out     [[ buffer(2) ]],
                        uint i                [[ thread_position_in_grid ]]
                    ) {
                        out[i] = metal::sin(a[i]) + metal::cos(b[i]);
                    }
                    """
                    guard let lib    = try? await device.makeLibrary(source: shaderSrc, options: nil),
                          let fn     = lib.makeFunction(name: "sinCosAdd"),
                          let pso    = try? await device.makeComputePipelineState(function: fn),
                          let bufA   = device.makeBuffer(length: floatSize, options: .storageModeShared),
                          let bufB   = device.makeBuffer(length: floatSize, options: .storageModeShared),
                          let bufOut = device.makeBuffer(length: floatSize, options: .storageModeShared)
                    else { gpuElapsed = -1.0; break }

                    let pA = bufA.contents().bindMemory(to: Float.self, capacity: count)
                    let pB = bufB.contents().bindMemory(to: Float.self, capacity: count)
                    for i in 0..<count { pA[i] = Float(i) * 0.001; pB[i] = Float(i) * 0.002 }

                    let gpuStart = Date()
                    guard let cmd = queue.makeCommandBuffer(),
                          let enc = cmd.makeComputeCommandEncoder() else { gpuElapsed = -1.0; break }
                    enc.setComputePipelineState(pso)
                    enc.setBuffer(bufA,   offset: 0, index: 0)
                    enc.setBuffer(bufB,   offset: 0, index: 1)
                    enc.setBuffer(bufOut, offset: 0, index: 2)
                    let tg   = MTLSize(width: pso.threadExecutionWidth, height: 1, depth: 1)
                    let grid = MTLSize(width: count, height: 1, depth: 1)
                    enc.dispatchThreads(grid, threadsPerThreadgroup: tg)
                    enc.endEncoding()
                    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                        cmd.addCompletedHandler { _ in cont.resume() }
                        cmd.commit()
                    }
                    gpuElapsed = Date().timeIntervalSince(gpuStart)
                }
                last = gpuElapsed ?? Date().timeIntervalSince(start)
            }
            return last
        }.value

        results[type] = elapsed
        isRunning = nil
    }

    func runAll() async {
        isRunningAll = true
        for type in BenchType.allCases { await run(type) }
        saveResult()
        isRunningAll = false
    }

    // Score: lower total runtime across all 8 benchmarks = higher score.
    // 6.0 s ceiling — a modern iPhone should total well under 1 s.
    var score: Int? {
        guard results.count == BenchType.allCases.count else { return nil }
        let total = BenchType.allCases.compactMap { results[$0] }.filter { $0 >= 0 }.reduce(0, +)
        return max(0, Int((6.0 - min(total, 6.0)) / 6.0 * 1000))
    }
}

// MARK: - BenchmarkView

struct BenchmarkView: View {

    @State private var runner = BenchmarkRunner()

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
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
                        if !runner.results.isEmpty { timingChart }
                        if !runner.resultHistory.isEmpty { historySection }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Benchmark")
    }

    // MARK: - Device Card

    private var deviceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse, isActive: runner.isRunning != nil || runner.isRunningAll)

            VStack(alignment: .leading, spacing: 2) {
                Text(runner.deviceName)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text("iOS \(runner.osVersion)")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.65))
            }

            Spacer()

            if let score = runner.score {
                VStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text("\(score)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                        Text("score")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.55))
                        if let prev = runner.previousResult {
                            let delta = score - prev.score
                            HStack(spacing: 2) {
                                Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(abs(delta))")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundStyle(delta >= 0 ? Color.green : Color.red)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    ShareLink(item: "DailyToolbox Benchmark: \(score) pts on \(runner.deviceName) (iOS \(runner.osVersion))") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.55))
                    }
                    .buttonStyle(.glass)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .glassEffect(.regular.tint(Color.cyan.opacity(0.07)),
                     in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(duration: 0.4), value: runner.score)
    }

    // MARK: - 2×4 Benchmark Grid

    private var benchmarkGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            ForEach(BenchmarkRunner.BenchType.allCases) { type in
                BenchCard(type: type, runner: runner)
            }
        }
    }

    // MARK: - Repeat Row

    private var repeatRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "repeat")
                .foregroundStyle(Color.primary.opacity(0.7))
            Text("Repeat")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.75))
            Spacer()
            Button {
                if runner.repeatCount > 1 { runner.repeatCount -= 1 }
            } label: {
                Image(systemName: "minus").frame(width: 30, height: 30).contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .disabled(runner.repeatCount <= 1)

            Text("\(runner.repeatCount)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .frame(minWidth: 32)
                .animation(.spring(duration: 0.2), value: runner.repeatCount)

            Button {
                if runner.repeatCount < 10 { runner.repeatCount += 1 }
            } label: {
                Image(systemName: "plus").frame(width: 30, height: 30).contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .disabled(runner.repeatCount >= 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Run All Button

    private var runAllButton: some View {
        Button {
            Task { await runner.runAll() }
        } label: {
            HStack(spacing: 10) {
                if runner.isRunningAll {
                    ProgressView().tint(.primary).scaleEffect(0.85)
                } else {
                    Image(systemName: "play.circle.fill").font(.system(size: 17))
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

    // MARK: - Timing Chart

    private var timingChart: some View {
        let maxTime = BenchmarkRunner.BenchType.allCases
            .compactMap { runner.results[$0] }.filter { $0 >= 0 }.max() ?? 1.0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Timing Comparison")
                    .font(.headline)
                    .foregroundStyle(Color.primary.opacity(0.85))
                Spacer()
                if let prev = runner.previousResult {
                    HStack(spacing: 4) {
                        Capsule()
                            .fill(Color.primary.opacity(0.30))
                            .frame(width: 14, height: 5)
                        Text(prev.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.45))
                    }
                }
            }

            ForEach(BenchmarkRunner.BenchType.allCases) { type in
                if let t = runner.results[type] {
                    let prevTime = runner.previousResult?.timings[type.rawValue]
                    HStack(spacing: 10) {
                        Image(systemName: type.icon)
                            .font(.caption)
                            .foregroundStyle(type.accentColor)
                            .frame(width: 14)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 10)
                                if t >= 0 {
                                    if let prevTime, prevTime >= 0 {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.28))
                                            .frame(
                                                width: geo.size.width * CGFloat(prevTime / maxTime),
                                                height: 6
                                            )
                                            .animation(.spring(duration: 0.7), value: prevTime)
                                    }
                                    Capsule()
                                        .fill(type.accentColor.opacity(0.85))
                                        .frame(
                                            width: geo.size.width * CGFloat(t / maxTime),
                                            height: 10
                                        )
                                        .animation(.spring(duration: 0.7), value: t)
                                }
                            }
                        }
                        .frame(height: 10)

                        Group {
                            if t < 0 {
                                Text("N/A")
                                    .foregroundStyle(Color.primary.opacity(0.45))
                            } else {
                                Text(t, format: .number.precision(.fractionLength(3)))
                                    .foregroundStyle(Color.primary.opacity(0.65))
                            }
                        }
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.5), value: runner.results.count)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Past Runs", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.75))
                .padding(.bottom, 2)
            Divider().overlay(Color.primary.opacity(0.15))
            ForEach(Array(runner.resultHistory.prefix(5).enumerated()), id: \.offset) { _, run in
                HStack {
                    Text(run.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.65))
                    Spacer()
                    Text("\(run.score) pts")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Individual Benchmark Card

private struct BenchCard: View {

    let type:   BenchmarkRunner.BenchType
    let runner: BenchmarkRunner

    var body: some View {
        let isActive     = runner.isRunning == type
        let isBusy       = runner.isRunning != nil || runner.isRunningAll
        let result       = runner.results[type]
        let currentRange = runner.selectedRange[type] ?? type.defaultRange

        VStack(alignment: .leading, spacing: 8) {

            // Icon + spinner
            HStack(alignment: .center) {
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(type.accentColor)
                    .symbolEffect(.pulse, isActive: isActive)
                Spacer()
                if isActive {
                    ProgressView().tint(type.accentColor).scaleEffect(0.7)
                }
            }

            // Name
            Text(LocalizedStringKey(type.rawValue))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Range picker
            Menu {
                ForEach(type.ranges, id: \.self) { r in
                    Button(type.rangeLabel(r)) { runner.selectedRange[type] = r }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(type.rangeLabel(currentRange))
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundStyle(Color.primary.opacity(0.65))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(.regular, in: Capsule())
            }

            // Result + delta
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                if let t = result {
                    if t < 0 {
                        Text("N/A")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.primary.opacity(0.45))
                    } else {
                        Text(t, format: .number.precision(.fractionLength(4)))
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(type.accentColor)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.4), value: t)
                        Text("s")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.55))
                    }
                } else {
                    Text("\u{2014}")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.primary.opacity(0.25))
                }
            }

            if let t = result, t >= 0,
               let prevTime = runner.previousResult?.timings[type.rawValue], prevTime >= 0 {
                let delta   = t - prevTime
                let faster  = delta < 0
                HStack(spacing: 2) {
                    Image(systemName: faster ? "arrow.down" : "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                    Text(abs(delta), format: .number.precision(.fractionLength(4)))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    Text("s")
                        .font(.system(size: 8))
                }
                .foregroundStyle(faster ? Color.green : Color.red)
                .transition(.opacity)
                .animation(.spring(duration: 0.4), value: delta)
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
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BenchmarkView()
    }
}
