/*
 MoonPhaseView.swift
 DailyToolbox

 Lunar phase calculator with animated moon illustration.
 Uses a pure astronomical algorithm — no network required.
*/

import SwiftUI

// MARK: - Moon Calculator

struct MoonInfo {
    let age:          Double   // days since last new moon (0–29.53)
    let illumination: Double   // fraction 0–1
    let phase:        MoonPhase
    let nextNewMoon:  Date
    let nextFullMoon: Date
    let distanceKm:   Double   // approximate Earth–Moon distance
}

enum MoonPhase: String, CaseIterable {
    case newMoon         = "New Moon"
    case waxingCrescent  = "Waxing Crescent"
    case firstQuarter    = "First Quarter"
    case waxingGibbous   = "Waxing Gibbous"
    case fullMoon        = "Full Moon"
    case waningGibbous   = "Waning Gibbous"
    case lastQuarter     = "Last Quarter"
    case waningCrescent  = "Waning Crescent"

    var icon: String {
        switch self {
        case .newMoon:        return "moonphase.new.moon"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter:   return "moonphase.first.quarter"
        case .waxingGibbous:  return "moonphase.waxing.gibbous"
        case .fullMoon:       return "moonphase.full.moon"
        case .waningGibbous:  return "moonphase.waning.gibbous"
        case .lastQuarter:    return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .newMoon:        return "Moon not visible"
        case .waxingCrescent: return "Growing, right-lit sliver"
        case .firstQuarter:   return "Right half illuminated"
        case .waxingGibbous:  return "More than half, growing"
        case .fullMoon:       return "Fully illuminated"
        case .waningGibbous:  return "More than half, shrinking"
        case .lastQuarter:    return "Left half illuminated"
        case .waningCrescent: return "Shrinking, left-lit sliver"
        }
    }
}

struct MoonCalculator {

    private static let synodicPeriod = 29.53058867  // days
    // Known new moon: 2000-01-06 18:14 UTC → JD 2451549.757
    private static let knownNewMoonJD = 2451549.757

    static func julianDate(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    static func calculate(for date: Date) -> MoonInfo {
        let jd = julianDate(date)
        let daysSinceKnown = jd - knownNewMoonJD
        let cycles = daysSinceKnown / synodicPeriod
        let age = (cycles - floor(cycles)) * synodicPeriod  // 0 … 29.53

        // Illumination: cos formula (0 at new, 1 at full)
        let illumination = (1 - cos(age / synodicPeriod * 2 * .pi)) / 2

        let phase: MoonPhase
        switch age {
        case 0..<1.85:  phase = .newMoon
        case 1.85..<7.38: phase = .waxingCrescent
        case 7.38..<9.22: phase = .firstQuarter
        case 9.22..<14.77: phase = .waxingGibbous
        case 14.77..<16.61: phase = .fullMoon
        case 16.61..<22.15: phase = .waningGibbous
        case 22.15..<23.99: phase = .lastQuarter
        default:         phase = .waningCrescent
        }

        // Distance: simple sinusoidal approximation (perigee ~356500, apogee ~406700)
        let distanceKm = 384400 - 27000 * cos(age / synodicPeriod * 2 * .pi)

        // Next new moon
        let daysToNextNew = synodicPeriod - age
        let nextNewMoon = date.addingTimeInterval(daysToNextNew * 86400)

        // Next full moon
        let daysToFull = age < 14.77
            ? 14.77 - age
            : synodicPeriod - age + 14.77
        let nextFullMoon = date.addingTimeInterval(daysToFull * 86400)

        return MoonInfo(
            age: age,
            illumination: illumination,
            phase: phase,
            nextNewMoon: nextNewMoon,
            nextFullMoon: nextFullMoon,
            distanceKm: distanceKm
        )
    }
}

// MARK: - Moon Disc Drawing

private struct MoonDiscView: View {
    let age: Double  // 0–29.53 days

    private static let synodicPeriod = 29.53058767

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let cx = size.width / 2
            let cy = size.height / 2

            // Dark background circle
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(Color(red: 0.07, green: 0.08, blue: 0.14))
            )

            // Lit moon surface (ivory)
            let litColor = Color(red: 0.96, green: 0.94, blue: 0.88)

            // Phase angle: 0 = new, π = full
            let phaseAngle = age / Self.synodicPeriod * 2 * Double.pi
            let isWaxing = age < Self.synodicPeriod / 2

            // The shadow ellipse x-radius: cos of phase angle
            // positive = shadow on right (waxing), negative = shadow on left (waning)
            let ellipseRx = abs(cos(phaseAngle)) * r

            // Draw lit half then cover with shadow
            // Lit half path: semicircle on the lit side
            var litPath = Path()
            if isWaxing {
                // right side lit
                litPath.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                               startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                litPath.closeSubpath()
            } else {
                // left side lit
                litPath.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                               startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                litPath.closeSubpath()
            }

            // Terminator ellipse (shadow boundary)
            var terminatorPath = Path()
            terminatorPath.addEllipse(in: CGRect(
                x: cx - ellipseRx, y: cy - r,
                width: ellipseRx * 2, height: r * 2
            ))

            let isNewMoon = age < 1.85 || age > 27.68

            if isNewMoon {
                // Just a very faint crescent glow
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                    with: .color(Color(red: 0.10, green: 0.11, blue: 0.20))
                )
            } else if age >= 14.77 && age < 16.61 {
                // Full moon — entirely lit
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                    with: .color(litColor)
                )
            } else {
                // Fill lit half
                ctx.fill(litPath, with: .color(litColor))

                // Blend terminator ellipse: add or subtract
                if isWaxing {
                    // cos > 0 means terminator is on left → shadow on left
                    if cos(phaseAngle) > 0 {
                        // Cover left portion with dark
                        ctx.fill(terminatorPath, with: .color(Color(red: 0.07, green: 0.08, blue: 0.14)))
                    } else {
                        // Terminator on right — add more lit area
                        ctx.fill(terminatorPath, with: .color(litColor))
                    }
                } else {
                    if cos(phaseAngle) > 0 {
                        ctx.fill(terminatorPath, with: .color(litColor))
                    } else {
                        ctx.fill(terminatorPath, with: .color(Color(red: 0.07, green: 0.08, blue: 0.14)))
                    }
                }
            }

            // Subtle crater hints on lit area
            let craters: [(x: Double, y: Double, r: Double, op: Double)] = [
                (0.30, 0.40, 0.06, 0.07), (0.60, 0.55, 0.04, 0.06),
                (0.45, 0.65, 0.07, 0.08), (0.55, 0.30, 0.05, 0.06),
                (0.25, 0.60, 0.04, 0.05), (0.70, 0.40, 0.03, 0.05)
            ]
            for c in craters {
                let crx = cx - r + c.x * r * 2
                let cry = cy - r + c.y * r * 2
                let cr  = c.r * r
                ctx.fill(
                    Path(ellipseIn: CGRect(x: crx - cr, y: cry - cr, width: cr * 2, height: cr * 2)),
                    with: .color(Color.black.opacity(c.op))
                )
            }

            // Outer glow ring
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(Color.white.opacity(0.08)),
                lineWidth: 1.5
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Stat Row

private struct MoonStatRow: View {
    let icon: String
    let label: LocalizedStringKey
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
    }
}

// MARK: - Main View

struct MoonPhaseView: View {

    @State private var selectedDate: Date = .now
    @Environment(\.colorScheme) private var colorScheme

    private var info: MoonInfo {
        MoonCalculator.calculate(for: selectedDate)
    }

    private var moonAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.88, green: 0.85, blue: 0.65)
            : Color(red: 0.55, green: 0.48, blue: 0.20)
    }
    private var blueAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.50, green: 0.72, blue: 1.00)
            : Color(red: 0.10, green: 0.38, blue: 0.80)
    }
    private var purpleAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.75, green: 0.55, blue: 1.00)
            : Color(red: 0.42, green: 0.15, blue: 0.78)
    }

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        moonVisual
                        phaseInfoCard
                        statsGrid
                        upcomingCard
                        datePicker
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Moon Phase")
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
                Color(red: 0.04, green: 0.04, blue: 0.16), Color(red: 0.06, green: 0.05, blue: 0.22), Color(red: 0.04, green: 0.04, blue: 0.16),
                Color(red: 0.06, green: 0.05, blue: 0.20), Color(red: 0.09, green: 0.07, blue: 0.28), Color(red: 0.06, green: 0.05, blue: 0.20),
                Color(red: 0.04, green: 0.04, blue: 0.14), Color(red: 0.06, green: 0.05, blue: 0.20), Color(red: 0.04, green: 0.04, blue: 0.14)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(moonAccent.opacity(0.18))
                    .frame(width: 50, height: 50)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(moonAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Moon Phase")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(selectedDate, format: .dateTime.day().month(.wide).year())
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            Spacer()
            Button("Today") {
                withAnimation(.spring(response: 0.4)) { selectedDate = .now }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(moonAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(moonAccent.opacity(0.15), in: Capsule())
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Moon Visual

    private var moonVisual: some View {
        VStack(spacing: 16) {
            MoonDiscView(age: info.age)
                .frame(width: 160, height: 160)
                .shadow(color: moonAccent.opacity(0.25), radius: 24)

            VStack(spacing: 4) {
                Text(LocalizedStringKey(info.phase.rawValue))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(info.phase.description)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: Phase Info Card

    private var phaseInfoCard: some View {
        HStack(spacing: 0) {
            phaseStatCell(
                value: info.illumination.formatted(.percent.precision(.fractionLength(0))),
                label: "Illuminated",
                icon: "circle.lefthalf.filled",
                color: moonAccent
            )
            Divider().frame(height: 44)
            phaseStatCell(
                value: String(format: "%.1f days", info.age),
                label: "Moon Age",
                icon: "clock.fill",
                color: blueAccent
            )
            Divider().frame(height: 44)
            phaseStatCell(
                value: info.distanceKm.formatted(.number.precision(.fractionLength(0))) + " km",
                label: "Distance",
                icon: "arrow.up.right",
                color: purpleAccent
            )
        }
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func phaseStatCell(value: String, label: LocalizedStringKey, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.callout, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(Color.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.primary.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Stats Grid (all 8 phases)

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LUNAR CYCLE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.primary.opacity(0.50))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(MoonPhase.allCases, id: \.self) { phase in
                    phaseCell(phase)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func phaseCell(_ phase: MoonPhase) -> some View {
        let isCurrent = phase == info.phase
        return VStack(spacing: 6) {
            Image(systemName: phase.icon)
                .font(.system(size: 22))
                .foregroundStyle(isCurrent ? moonAccent : Color.primary.opacity(0.40))
            Text(LocalizedStringKey(phase.rawValue))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isCurrent ? moonAccent : Color.primary.opacity(0.40))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrent ? moonAccent.opacity(0.15) : Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isCurrent ? moonAccent.opacity(0.50) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: Upcoming Events

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPCOMING")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.primary.opacity(0.50))

            MoonStatRow(
                icon: "moonphase.new.moon",
                label: "Next New Moon",
                value: info.nextNewMoon.formatted(date: .abbreviated, time: .omitted),
                accent: blueAccent
            )
            Divider().opacity(0.3)
            MoonStatRow(
                icon: "moonphase.full.moon",
                label: "Next Full Moon",
                value: info.nextFullMoon.formatted(date: .abbreviated, time: .omitted),
                accent: moonAccent
            )
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Date Picker

    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BROWSE DATE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.primary.opacity(0.50))

            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(moonAccent)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MoonPhaseView()
    }
}
