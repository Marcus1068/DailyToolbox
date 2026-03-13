/*
 ResistorColorCodeView.swift
 DailyToolbox

 4-band and 5-band resistor color code calculator.
 Supports color→value and value→color decoding.
*/

import SwiftUI

// MARK: - Model

enum ResistorBandColor: String, CaseIterable, Identifiable {
    case black  = "Black"
    case brown  = "Brown"
    case red    = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green  = "Green"
    case blue   = "Blue"
    case violet = "Violet"
    case grey   = "Grey"
    case white  = "White"
    case gold   = "Gold"
    case silver = "Silver"
    case none   = "None"

    var id: String { rawValue }

    var displayColor: Color {
        switch self {
        case .black:  return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .brown:  return Color(red: 0.55, green: 0.27, blue: 0.07)
        case .red:    return Color(red: 0.85, green: 0.10, blue: 0.10)
        case .orange: return Color(red: 1.00, green: 0.55, blue: 0.00)
        case .yellow: return Color(red: 0.95, green: 0.90, blue: 0.05)
        case .green:  return Color(red: 0.10, green: 0.65, blue: 0.18)
        case .blue:   return Color(red: 0.10, green: 0.30, blue: 0.85)
        case .violet: return Color(red: 0.55, green: 0.10, blue: 0.75)
        case .grey:   return Color(red: 0.50, green: 0.50, blue: 0.50)
        case .white:  return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .gold:   return Color(red: 0.85, green: 0.70, blue: 0.10)
        case .silver: return Color(red: 0.72, green: 0.72, blue: 0.76)
        case .none:   return Color(red: 0.82, green: 0.72, blue: 0.55)
        }
    }

    var labelColor: Color {
        switch self {
        case .black, .blue, .violet: return .white
        default: return .black
        }
    }

    // Digit value (nil = not valid as a digit)
    var digit: Int? {
        switch self {
        case .black:  return 0
        case .brown:  return 1
        case .red:    return 2
        case .orange: return 3
        case .yellow: return 4
        case .green:  return 5
        case .blue:   return 6
        case .violet: return 7
        case .grey:   return 8
        case .white:  return 9
        default:      return nil
        }
    }

    // Multiplier value (nil = not valid as multiplier)
    var multiplier: Double? {
        switch self {
        case .black:  return 1
        case .brown:  return 10
        case .red:    return 100
        case .orange: return 1_000
        case .yellow: return 10_000
        case .green:  return 100_000
        case .blue:   return 1_000_000
        case .violet: return 10_000_000
        case .grey:   return 100_000_000
        case .white:  return 1_000_000_000
        case .gold:   return 0.1
        case .silver: return 0.01
        default:      return nil
        }
    }

    // Tolerance string (nil = not valid as tolerance)
    var tolerance: String? {
        switch self {
        case .brown:  return "±1%"
        case .red:    return "±2%"
        case .orange: return "±0.05%"
        case .yellow: return "±0.02%"
        case .green:  return "±0.5%"
        case .blue:   return "±0.25%"
        case .violet: return "±0.1%"
        case .grey:   return "±0.05%"
        case .gold:   return "±5%"
        case .silver: return "±10%"
        case .none:   return "±20%"
        default:      return nil
        }
    }

    // Valid colors for digit bands (first bands)
    static let digitColors: [ResistorBandColor] = [
        .black, .brown, .red, .orange, .yellow,
        .green, .blue, .violet, .grey, .white
    ]

    // Valid colors for the first digit (no black)
    static let firstDigitColors: [ResistorBandColor] = [
        .brown, .red, .orange, .yellow,
        .green, .blue, .violet, .grey, .white
    ]

    static let multiplierColors: [ResistorBandColor] = [
        .black, .brown, .red, .orange, .yellow,
        .green, .blue, .violet, .grey, .white, .gold, .silver
    ]

    static let toleranceColors: [ResistorBandColor] = [
        .brown, .red, .orange, .yellow, .green,
        .blue, .violet, .grey, .gold, .silver, .none
    ]
}

// MARK: - Resistor Value Formatter

private func formatResistance(_ ohms: Double) -> String {
    if ohms >= 1_000_000_000 {
        let v = ohms / 1_000_000_000
        return v.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(v)) GΩ" : String(format: "%.2g GΩ", v)
    } else if ohms >= 1_000_000 {
        let v = ohms / 1_000_000
        return v.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(v)) MΩ" : String(format: "%.2g MΩ", v)
    } else if ohms >= 1_000 {
        let v = ohms / 1_000
        return v.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(v)) kΩ" : String(format: "%.2g kΩ", v)
    } else if ohms < 1 {
        return String(format: "%.2g Ω", ohms)
    } else {
        return ohms.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(ohms)) Ω" : String(format: "%.2g Ω", ohms)
    }
}

// MARK: - Resistor Body Drawing

private struct ResistorBodyView: View {
    let bands: [ResistorBandColor]
    let isFiveBand: Bool

    private var activeBands: [ResistorBandColor] {
        isFiveBand ? Array(bands.prefix(5)) : Array(bands.prefix(4))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bodyWidth  = w * 0.68
            let bodyHeight = h * 0.44
            let bodyX = (w - bodyWidth) / 2
            let leadLength = (w - bodyWidth) / 2

            // Left lead
            Path { p in
                p.move(to: CGPoint(x: 0, y: h / 2))
                p.addLine(to: CGPoint(x: leadLength, y: h / 2))
            }
            .stroke(Color.primary.opacity(0.55), lineWidth: 2)

            // Right lead
            Path { p in
                p.move(to: CGPoint(x: w - leadLength, y: h / 2))
                p.addLine(to: CGPoint(x: w, y: h / 2))
            }
            .stroke(Color.primary.opacity(0.55), lineWidth: 2)

            // Body (beige ceramic)
            RoundedRectangle(cornerRadius: bodyHeight * 0.38)
                .fill(Color(red: 0.85, green: 0.76, blue: 0.58))
                .frame(width: bodyWidth, height: bodyHeight)
                .position(x: w / 2, y: h / 2)

            // Color bands
            let count = activeBands.count
            let bandWidth = bodyWidth * 0.10
            let spacing = bodyWidth / Double(count + 1)

            ForEach(0..<count, id: \.self) { i in
                let xPos = bodyX + spacing * Double(i + 1)
                RoundedRectangle(cornerRadius: 2)
                    .fill(activeBands[i].displayColor)
                    .frame(width: bandWidth, height: bodyHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
                    )
                    .position(x: xPos + bandWidth / 2, y: h / 2)
            }

            // Body outline
            RoundedRectangle(cornerRadius: bodyHeight * 0.38)
                .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                .frame(width: bodyWidth, height: bodyHeight)
                .position(x: w / 2, y: h / 2)
        }
        .frame(height: 72)
    }
}

// MARK: - Band Picker Row

private struct BandPickerRow: View {
    let label: LocalizedStringKey
    let colors: [ResistorBandColor]
    @Binding var selection: ResistorBandColor
    let accent: Color

    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.55))
                .frame(width: 72, alignment: .leading)

            Button {
                showPicker = true
            } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selection.displayColor)
                        .frame(width: 28, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5)
                        )
                    Text(LocalizedStringKey(selection.rawValue))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accent.opacity(0.20), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            ColorPickerSheet(label: label, colors: colors, selection: $selection)
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Color Picker Sheet

private struct ColorPickerSheet: View {
    let label: LocalizedStringKey
    let colors: [ResistorBandColor]
    @Binding var selection: ResistorBandColor
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(colors) { color in
                        Button {
                            selection = color
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(color.displayColor)
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                color == selection
                                                    ? Color.blue : Color.black.opacity(0.15),
                                                lineWidth: color == selection ? 2.5 : 0.5
                                            )
                                    )
                                    .shadow(
                                        color: color == selection ? Color.blue.opacity(0.30) : .clear,
                                        radius: 6
                                    )
                                Text(LocalizedStringKey(color.rawValue))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.primary.opacity(0.70))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Main View

struct ResistorColorCodeView: View {

    @State private var isFiveBand = false

    // 4-band: d1 d2 mult tol
    // 5-band: d1 d2 d3 mult tol
    @State private var band1: ResistorBandColor = .brown
    @State private var band2: ResistorBandColor = .black
    @State private var band3: ResistorBandColor = .black   // 5-band only
    @State private var bandMult: ResistorBandColor = .brown
    @State private var bandTol: ResistorBandColor = .gold

    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 1.00, green: 0.72, blue: 0.20)
            : Color(red: 0.65, green: 0.38, blue: 0.00)
    }

    // MARK: Computation

    private var resistance: Double? {
        guard let m = bandMult.multiplier else { return nil }
        if isFiveBand {
            guard let d1 = band1.digit, let d2 = band2.digit, let d3 = band3.digit else { return nil }
            return Double(d1 * 100 + d2 * 10 + d3) * m
        } else {
            guard let d1 = band1.digit, let d2 = band2.digit else { return nil }
            return Double(d1 * 10 + d2) * m
        }
    }

    private var toleranceText: String {
        bandTol.tolerance ?? "—"
    }

    private var allBands: [ResistorBandColor] {
        isFiveBand
            ? [band1, band2, band3, bandMult, bandTol]
            : [band1, band2, bandMult, bandTol]
    }

    private var minValue: Double? {
        guard let r = resistance,
              let pct = bandTol.tolerance,
              let num = Double(pct.replacingOccurrences(of: "±", with: "").replacingOccurrences(of: "%", with: ""))
        else { return nil }
        return r * (1 - num / 100)
    }

    private var maxValue: Double? {
        guard let r = resistance,
              let pct = bandTol.tolerance,
              let num = Double(pct.replacingOccurrences(of: "±", with: "").replacingOccurrences(of: "%", with: ""))
        else { return nil }
        return r * (1 + num / 100)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { resistorPreview }
                    GlassEffectContainer { resultCard }
                    GlassEffectContainer { bandSelectors }
                    GlassEffectContainer { referenceCard }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Resistor Color Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0,0.0],[0.5,0.0],[1.0,0.0],
                [0.0,0.5],[0.5,0.5],[1.0,0.5],
                [0.0,1.0],[0.5,1.0],[1.0,1.0]
            ],
            colors: [
                Color(red:0.12,green:0.07,blue:0.02), Color(red:0.16,green:0.10,blue:0.03), Color(red:0.12,green:0.07,blue:0.02),
                Color(red:0.16,green:0.10,blue:0.03), Color(red:0.22,green:0.14,blue:0.04), Color(red:0.16,green:0.10,blue:0.03),
                Color(red:0.10,green:0.06,blue:0.01), Color(red:0.14,green:0.09,blue:0.02), Color(red:0.10,green:0.06,blue:0.01)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.60)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                Image(systemName: "waveform.path.ecg")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Resistor Color Code")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Read color bands to find resistance")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.60))
            }
            Spacer()
            // Band count toggle
            Picker("Bands", selection: $isFiveBand) {
                Text("4-Band").tag(false)
                Text("5-Band").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Resistor Preview

    private var resistorPreview: some View {
        VStack(spacing: 12) {
            ResistorBodyView(bands: allBands, isFiveBand: isFiveBand)
                .padding(.horizontal, 20)

            // Band labels
            HStack(spacing: 0) {
                ForEach(Array(allBands.enumerated()), id: \.offset) { i, band in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(band.displayColor)
                            .frame(width: 20, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.black.opacity(0.20), lineWidth: 0.5)
                            )
                        Text(bandLabel(index: i))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private func bandLabel(index: Int) -> LocalizedStringKey {
        if isFiveBand {
            let keys: [LocalizedStringKey] = ["1st", "2nd", "3rd", "×", "Tol"]
            return keys[index]
        } else {
            let keys: [LocalizedStringKey] = ["1st", "2nd", "×", "Tol"]
            return keys[index]
        }
    }

    // MARK: Result Card

    private var resultCard: some View {
        VStack(spacing: 10) {
            if let r = resistance {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatResistance(r))
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())
                    Text(toleranceText)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.60))
                }

                if let lo = minValue, let hi = maxValue {
                    Text("Range: \(formatResistance(lo)) – \(formatResistance(hi))")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.50))
                        .contentTransition(.numericText())
                }
            } else {
                Text("Select valid bands")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Band Selectors

    private var bandSelectors: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COLOR BANDS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.primary.opacity(0.50))

            BandPickerRow(label: "1st Digit", colors: ResistorBandColor.firstDigitColors,
                          selection: $band1, accent: accentColor)
            Divider().opacity(0.3)
            BandPickerRow(label: "2nd Digit", colors: ResistorBandColor.digitColors,
                          selection: $band2, accent: accentColor)

            if isFiveBand {
                Divider().opacity(0.3)
                BandPickerRow(label: "3rd Digit", colors: ResistorBandColor.digitColors,
                              selection: $band3, accent: accentColor)
            }

            Divider().opacity(0.3)
            BandPickerRow(label: "Multiplier", colors: ResistorBandColor.multiplierColors,
                          selection: $bandMult, accent: accentColor)
            Divider().opacity(0.3)
            BandPickerRow(label: "Tolerance", colors: ResistorBandColor.toleranceColors,
                          selection: $bandTol, accent: accentColor)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Reference Card

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK REFERENCE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.primary.opacity(0.50))

            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    Text("Color").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Digit").frame(width: 50, alignment: .center)
                    Text("Multiplier").frame(width: 88, alignment: .center)
                    Text("Tolerance").frame(width: 72, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.45))
                .padding(.bottom, 2)

                Divider().opacity(0.3)

                ForEach(ResistorBandColor.allCases.filter { $0 != .none }) { color in
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color.displayColor)
                                .frame(width: 16, height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5)
                                )
                            Text(LocalizedStringKey(color.rawValue))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.primary.opacity(0.80))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(color.digit.map { "\($0)" } ?? "—")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.primary.opacity(0.65))
                            .frame(width: 50, alignment: .center)

                        Text(color.multiplier.map { formatResistance($0) } ?? "—")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.primary.opacity(0.65))
                            .frame(width: 88, alignment: .center)
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)

                        Text(color.tolerance ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.primary.opacity(0.65))
                            .frame(width: 72, alignment: .trailing)
                    }
                }

                // None row for tolerance
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ResistorBandColor.none.displayColor)
                            .frame(width: 16, height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5)
                            )
                        Text("None")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.primary.opacity(0.80))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("—").font(.system(size: 11, design: .monospaced)).foregroundStyle(Color.primary.opacity(0.65)).frame(width: 50, alignment: .center)
                    Text("—").font(.system(size: 11, design: .monospaced)).foregroundStyle(Color.primary.opacity(0.65)).frame(width: 88, alignment: .center)
                    Text("±20%").font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.primary.opacity(0.65)).frame(width: 72, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResistorColorCodeView()
    }
}
