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
//  SunriseView.swift
//  DailyToolbox
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Location Manager

@Observable
@MainActor
final class SunLocationManager: NSObject {
    var coordinate:          CLLocationCoordinate2D? = nil
    var locationName:        String = ""
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isSearching:         Bool = true

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus     = manager.authorizationStatus
    }

    func start() {
        isSearching = true
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

extension SunLocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        // Update coordinate/searching state on main actor immediately
        Task { @MainActor [weak self] in
            self?.coordinate  = loc.coordinate
            self?.isSearching = false
        }
        // Geocode in a detached nonisolated Task — MKReverseGeocodingRequest is not Sendable
        Task.detached { [weak self] in
            guard let request = MKReverseGeocodingRequest(location: loc),
                  let items   = try? await request.mapItems,
                  let repr    = items.first?.addressRepresentations else { return }
            let name = repr.cityWithContext(.automatic) ?? repr.cityName ?? ""
            await MainActor.run { [weak self] in self?.locationName = name }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in self?.isSearching = false }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            authorizationStatus = manager.authorizationStatus
            if isAuthorized { manager.requestLocation() }
        }
    }
}

// MARK: - Solar Calculator

struct SolarTimes {
    let sunrise:               Date?
    let sunset:                Date?
    let solarNoon:             Date?
    let civilDawn:             Date?
    let civilDusk:             Date?
    let goldenHourMorningEnd:  Date?   // when sun rises above 6°
    let goldenHourEveningStart: Date?  // when sun drops below 6°

    var dayLength: TimeInterval? {
        guard let r = sunrise, let s = sunset else { return nil }
        return s.timeIntervalSince(r)
    }
}

struct SolarCalculator {

    static func calculate(date: Date, lat: Double, lon: Double) -> SolarTimes {
        SolarTimes(
            sunrise:               time(date: date, lat: lat, lon: lon, zenith: 90.833, isMorning: true),
            sunset:                time(date: date, lat: lat, lon: lon, zenith: 90.833, isMorning: false),
            solarNoon:             noon(date: date, lat: lat, lon: lon),
            civilDawn:             time(date: date, lat: lat, lon: lon, zenith: 96.0,   isMorning: true),
            civilDusk:             time(date: date, lat: lat, lon: lon, zenith: 96.0,   isMorning: false),
            goldenHourMorningEnd:  time(date: date, lat: lat, lon: lon, zenith: 84.0,   isMorning: true),
            goldenHourEveningStart: time(date: date, lat: lat, lon: lon, zenith: 84.0,  isMorning: false)
        )
    }

    /// Current sun elevation above horizon in degrees.
    static func elevation(at date: Date, lat: Double, lon: Double) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let h  = Double(cal.component(.hour,   from: date))
        let mi = Double(cal.component(.minute, from: date))
        let s  = Double(cal.component(.second, from: date))
        let fracDay = (h + mi / 60.0 + s / 3600.0) / 24.0
        let T   = (julianDay(date: date) + fracDay - 2451545.0) / 36525.0
        let (eqTime, dec) = eqTimeAndDec(T: T)
        let tst = (h * 60 + mi + s / 60) + eqTime + 4 * lon
        let ha  = ((tst / 4) - 180) * .pi / 180
        let φ   = lat * .pi / 180
        return asin(sin(φ) * sin(dec) + cos(φ) * cos(dec) * cos(ha)) * 180 / .pi
    }

    // MARK: Private helpers

    private static func julianDay(date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let y = cal.component(.year,  from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day,   from: date)
        let A = (14 - m) / 12
        let Y = y + 4800 - A
        let M = m + 12 * A - 3
        let JDN = d + (153 * M + 2) / 5 + 365 * Y + Y / 4 - Y / 100 + Y / 400 - 32045
        return Double(JDN) - 0.5
    }

    private static func eqTimeAndDec(T: Double) -> (eqTime: Double, dec: Double) {
        let L0  = (280.46646 + T * (36000.76983 + T * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let M_d = (357.52911 + T * (35999.05029 - T * 0.0001537)).truncatingRemainder(dividingBy: 360)
        let M_r = M_d * .pi / 180
        let C   =   sin(M_r)     * (1.914602 - T * (0.004817 + T * 0.000014))
                  + sin(2 * M_r) * (0.019993 - T * 0.000101)
                  + sin(3 * M_r) *  0.000289
        let ω       = 125.04 - 1934.136 * T
        let lambda  = L0 + C - 0.00569 - 0.00478 * sin(ω * .pi / 180)
        let epsilon = 23.439291111 - T * (0.013004167 + T * (1.64e-7 - T * 5.04e-7))
                      + 0.00256 * cos(ω * .pi / 180)
        let dec     = asin(sin(epsilon * .pi / 180) * sin(lambda * .pi / 180))
        let L0_r    = L0 * .pi / 180
        let y       = tan(epsilon * .pi / 180 / 2)
        let y2      = y * y
        let e       = 0.016708634
        let eqTime  = 4 * (180 / .pi) * (
             y2 * sin(2 * L0_r)
           - 2  * e  * sin(M_r)
           + 4  * e  * y2 * sin(M_r) * cos(2 * L0_r)
           - 0.5     * y2 * y2 * sin(4 * L0_r)
           - 1.25    * e  * e  * sin(2 * M_r)
        )
        return (eqTime, dec)
    }

    private static func utcMidnight(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.startOfDay(for: date)
    }

    private static func noon(date: Date, lat: Double, lon: Double) -> Date? {
        let JD = julianDay(date: date)
        let (eqTime, _) = eqTimeAndDec(T: (JD - 2451545.0) / 36525.0)
        return utcMidnight(date).addingTimeInterval((720 - 4 * lon - eqTime) * 60)
    }

    private static func time(date: Date, lat: Double, lon: Double,
                             zenith: Double, isMorning: Bool) -> Date? {
        let JD = julianDay(date: date)
        let T  = (JD - 2451545.0) / 36525.0
        let (eqTime, dec) = eqTimeAndDec(T: T)
        let φ       = lat    * .pi / 180
        let zenith_r = zenith * .pi / 180
        let cosHA   = (cos(zenith_r) - sin(φ) * sin(dec)) / (cos(φ) * cos(dec))
        guard cosHA >= -1 && cosHA <= 1 else { return nil }
        let HA   = acos(cosHA) * 180 / .pi
        let nUTC = 720 - 4 * lon - eqTime
        let tUTC = isMorning ? nUTC - 4 * HA : nUTC + 4 * HA
        return utcMidnight(date).addingTimeInterval(tUTC * 60)
    }
}

// MARK: - Sky Phase

enum SkyPhase: Equatable {
    case night, civilDawn, goldenMorning, day, goldenEvening, civilDusk

    static func current(times: SolarTimes, now: Date) -> SkyPhase {
        let dawn  = times.civilDawn             ?? times.sunrise?.addingTimeInterval(-1800)
        let ghM   = times.goldenHourMorningEnd  ?? times.sunrise?.addingTimeInterval(3600)
        let ghE   = times.goldenHourEveningStart ?? times.sunset?.addingTimeInterval(-3600)
        let dusk  = times.civilDusk             ?? times.sunset?.addingTimeInterval(1800)

        guard let dawn, let ghM, let ghE, let dusk,
              let rise = times.sunrise, let set = times.sunset else { return .night }

        if now < dawn            { return .night }
        if now < rise            { return .civilDawn }
        if now < ghM             { return .goldenMorning }
        if now < ghE             { return .day }
        if now < set             { return .goldenEvening }
        if now < dusk            { return .civilDusk }
        return .night
    }

    var backgroundColors: [Color] {
        switch self {
        case .night:
            return [Color(red:0.02, green:0.04, blue:0.18), Color(red:0.04, green:0.06, blue:0.24)]
        case .civilDawn:
            return [Color(red:0.08, green:0.05, blue:0.30), Color(red:0.28, green:0.12, blue:0.36), Color(red:0.50, green:0.22, blue:0.18)]
        case .goldenMorning:
            return [Color(red:0.96, green:0.60, blue:0.18), Color(red:0.90, green:0.35, blue:0.15), Color(red:0.38, green:0.20, blue:0.42)]
        case .day:
            return [Color(red:0.18, green:0.42, blue:0.90), Color(red:0.44, green:0.70, blue:1.00)]
        case .goldenEvening:
            return [Color(red:0.90, green:0.45, blue:0.10), Color(red:0.75, green:0.25, blue:0.18), Color(red:0.28, green:0.14, blue:0.36)]
        case .civilDusk:
            return [Color(red:0.14, green:0.08, blue:0.34), Color(red:0.06, green:0.05, blue:0.20)]
        }
    }
}

// MARK: - Sun Arc Scene

private let sunStars: [(x: Double, y: Double, op: Double, sz: Double)] = [
    (0.06, 0.10, 0.65, 2.0), (0.16, 0.22, 0.42, 1.5), (0.30, 0.06, 0.72, 2.5),
    (0.48, 0.15, 0.48, 2.0), (0.60, 0.08, 0.60, 1.5), (0.74, 0.24, 0.52, 2.0),
    (0.84, 0.12, 0.55, 2.5), (0.93, 0.19, 0.40, 1.5), (0.38, 0.28, 0.35, 1.5),
    (0.55, 0.32, 0.30, 1.0), (0.20, 0.35, 0.28, 1.0)
]

private struct SunArcSceneView: View {
    let progress:  Double      // 0 = sunrise edge, 1 = sunset edge, <0 night
    let skyPhase:  SkyPhase
    let elevation: Double?

    var body: some View {
        GeometryReader { geo in
            let w  = geo.size.width
            let h  = geo.size.height
            let cx = w / 2
            let cy = h * 0.90
            let r  = w * 0.40

            // Stars / moon at night
            if skyPhase == .night || skyPhase == .civilDawn || skyPhase == .civilDusk {
                let starOpacity: Double = skyPhase == .night ? 1.0 : 0.4
                ForEach(sunStars.indices, id: \.self) { i in
                    let s = sunStars[i]
                    Circle()
                        .fill(Color.white.opacity(s.op * starOpacity))
                        .frame(width: s.sz, height: s.sz)
                        .position(x: s.x * w, y: s.y * cy)
                }
            }

            // Arc track
            Path { p in
                p.addArc(center: CGPoint(x: cx, y: cy),
                         radius: r,
                         startAngle: .degrees(180),
                         endAngle: .degrees(0),
                         clockwise: false)
            }
            .stroke(Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))

            // Horizon line
            Path { p in
                p.move(to: CGPoint(x: 4, y: cy))
                p.addLine(to: CGPoint(x: w - 4, y: cy))
            }
            .stroke(Color.white.opacity(0.22), lineWidth: 1)

            // Sun disc
            let clampedProgress = max(0.0, min(1.0, progress))
            let angle  = Double.pi * (1.0 - clampedProgress)   // π=left → 0=right
            let sunX   = cx + r * cos(angle)
            let sunY   = cy - r * abs(sin(angle))
            let isVisible = progress >= 0 && progress <= 1
            let isAbove   = sunY < cy

            if isVisible || progress < 0 {
                let posX = isVisible ? sunX : cx
                let posY = isVisible ? (isAbove ? sunY : cy - 6) : cy - 6

                ZStack {
                    Circle()
                        .fill(sunGlowColor.opacity(0.20))
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(sunGlowColor.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(sunBodyColor)
                        .frame(width: 26, height: 26)
                }
                .shadow(color: sunGlowColor.opacity(0.55), radius: 20)
                .position(x: posX, y: posY)
            }

            // Elevation badge
            if let elev = elevation {
                let sign = elev >= 0 ? "+" : ""
                Text("\(sign)\(String(format: "%.1f", elev))°")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12), in: Capsule())
                    .position(x: w - 44, y: h - 12)
            }
        }
        .frame(height: 155)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var sunBodyColor: Color {
        switch skyPhase {
        case .night:                      return Color.white.opacity(0.80)
        case .civilDawn, .civilDusk:      return Color(red: 1.0, green: 0.82, blue: 0.50)
        case .goldenMorning, .goldenEvening: return Color(red: 1.0, green: 0.75, blue: 0.10)
        case .day:                        return Color(red: 1.0, green: 0.97, blue: 0.60)
        }
    }

    private var sunGlowColor: Color {
        switch skyPhase {
        case .night:  return .white
        case .day:    return Color(red: 1.0, green: 0.90, blue: 0.45)
        default:      return Color(red: 1.0, green: 0.60, blue: 0.12)
        }
    }
}

// MARK: - Time Card Row

private struct SunEventRow: View {
    let icon:      String
    let label:     LocalizedStringKey
    let time:      Date?
    let accent:    Color
    let formatter: DateFormatter

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
                if let t = time {
                    Text(formatter.string(from: t))
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText())
                } else {
                    Text("—")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary.opacity(0.28))
                }
            }
            Spacer()
        }
    }
}

// MARK: - Main View

struct SunriseView: View {

    @State private var locationManager = SunLocationManager()
    @State private var now:   Date = Date()
    @State private var timer: Timer? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    // MARK: Adaptive colors

    private var goldAccent: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.82, blue: 0.22)
                             : Color(red: 0.68, green: 0.48, blue: 0.00)
    }
    private var roseAccent: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.55, blue: 0.35)
                             : Color(red: 0.80, green: 0.25, blue: 0.10)
    }
    private var blueAccent: Color {
        colorScheme == .dark ? Color(red: 0.45, green: 0.74, blue: 1.00)
                             : Color(red: 0.08, green: 0.42, blue: 0.88)
    }
    private var purpleAccent: Color {
        colorScheme == .dark ? Color(red: 0.75, green: 0.55, blue: 1.00)
                             : Color(red: 0.45, green: 0.15, blue: 0.75)
    }
    private var cyanAccent: Color {
        colorScheme == .dark ? Color(red: 0.40, green: 0.90, blue: 1.00)
                             : Color(red: 0.05, green: 0.52, blue: 0.72)
    }

    // MARK: Computed

    private var solarTimes: SolarTimes? {
        guard let coord = locationManager.coordinate else { return nil }
        return SolarCalculator.calculate(date: now, lat: coord.latitude, lon: coord.longitude)
    }

    private var skyPhase: SkyPhase {
        guard let t = solarTimes else { return .night }
        return SkyPhase.current(times: t, now: now)
    }

    private var sunProgress: Double {
        guard let t = solarTimes,
              let rise = t.sunrise, let set = t.sunset else { return -1 }
        let total   = set.timeIntervalSince(rise)
        let elapsed = now.timeIntervalSince(rise)
        return max(-0.05, min(1.05, elapsed / total))
    }

    private var sunElevation: Double? {
        guard let coord = locationManager.coordinate else { return nil }
        return SolarCalculator.elevation(at: now, lat: coord.latitude, lon: coord.longitude)
    }

    private var dayLengthText: String {
        guard let sec = solarTimes?.dayLength else { return "—" }
        let h = Int(sec) / 3600
        let m = (Int(sec) % 3600) / 60
        return String(format: "%dh %02dm", h, m)
    }

    private var solarCopyText: String? {
        guard let t = solarTimes,
              let rise = t.sunrise,
              let set  = t.sunset else { return nil }
        return "Sunrise: \(timeFormatter.string(from: rise)) · Sunset: \(timeFormatter.string(from: set)) · Day length: \(dayLengthText)"
    }

    private var nextEventText: String? {
        guard let t = solarTimes else { return nil }
        let events: [(Date?, String)] = [
            (t.civilDawn,             NSLocalizedString("Civil Dawn",   comment: "")),
            (t.sunrise,               NSLocalizedString("Sunrise",      comment: "")),
            (t.goldenHourMorningEnd,  NSLocalizedString("Golden Hour",  comment: "")),
            (t.solarNoon,             NSLocalizedString("Solar Noon",   comment: "")),
            (t.goldenHourEveningStart,NSLocalizedString("Golden Hour",  comment: "")),
            (t.sunset,                NSLocalizedString("Sunset",       comment: "")),
            (t.civilDusk,             NSLocalizedString("Civil Dusk",   comment: ""))
        ]
        let upcoming = events.compactMap { (d, name) -> (TimeInterval, String)? in
            guard let d, d > now else { return nil }
            return (d.timeIntervalSince(now), name)
        }.sorted { $0.0 < $1.0 }.first
        guard let (interval, name) = upcoming else { return nil }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let timeStr = h > 0
            ? String(format: NSLocalizedString("%dh %02dm", comment: ""), h, m)
            : String(format: NSLocalizedString("%dm", comment: ""), m)
        return "\(name) \(NSLocalizedString("in", comment: "")) \(timeStr)"
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        skyScene
                        timesGrid
                        goldenHourCard
                        if solarTimes?.dayLength != nil { dayLengthCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("Sunrise & Sunset")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            locationManager.start()
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Task { @MainActor in self.now = Date() }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: Background

    private var background: some View {
        let colors = skyPhase.backgroundColors
        return MeshGradient(
            width: 2, height: 2,
            points: [[0,0],[1,0],[0,1],[1,1]],
            colors: colors.count >= 4
                ? Array(colors.prefix(4))
                : [colors[0], colors.last ?? colors[0], colors.count > 1 ? colors[1] : colors[0], colors.last ?? colors[0]]
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 90), value: skyPhase)
    }

    // MARK: Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.00, green: 0.75, blue: 0.20).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.30),
                                     Color(red: 1.0, green: 0.55, blue: 0.10)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Sunrise & Sunset")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                if locationManager.isSearching {
                    Text("Locating…")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.50))
                } else if !locationManager.locationName.isEmpty {
                    Text(locationManager.locationName)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.55))
                } else if !locationManager.isAuthorized {
                    Text("Location permission needed")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.50))
                    if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                Task { @MainActor in await UIApplication.shared.open(url) }
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(goldAccent)
                    }
                } else {
                    Text(now, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.55))
                }
            }
            Spacer()
            // Live clock
            VStack(alignment: .trailing, spacing: 2) {
                Text(now, style: .time)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.primary)
                if let next = nextEventText {
                    Text(next)
                        .font(.caption2)
                        .foregroundStyle(goldAccent.opacity(0.85))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Sky Scene

    private var skyScene: some View {
        SunArcSceneView(
            progress:  sunProgress,
            skyPhase:  skyPhase,
            elevation: sunElevation
        )
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Times Grid

    private var timesGrid: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                sunEventCell(icon: "moon.stars.fill",   label: "Civil Dawn",  time: solarTimes?.civilDawn,   accent: purpleAccent)
                sunEventCell(icon: "sunrise.fill",       label: "Sunrise",     time: solarTimes?.sunrise,     accent: roseAccent)
                sunEventCell(icon: "sun.max.fill",       label: "Solar Noon",  time: solarTimes?.solarNoon,   accent: goldAccent)
                sunEventCell(icon: "sunset.fill",        label: "Sunset",      time: solarTimes?.sunset,      accent: roseAccent)
                sunEventCell(icon: "moon.fill",          label: "Civil Dusk",  time: solarTimes?.civilDusk,   accent: purpleAccent)
                sunEventCell(icon: "clock.fill",         label: "Day Length",  displayText: dayLengthText,    accent: blueAccent)
            }
            if let copyText = solarCopyText {
                HStack(spacing: 8) {
                    Spacer()
                    Button { UIPasteboard.general.string = copyText } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Copy")
                    ShareLink(item: copyText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }

    private func sunEventCell(icon: String, label: LocalizedStringKey, time: Date? = nil,
                               displayText: String? = nil, accent: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.50))
                if let t = time {
                    Text(timeFormatter.string(from: t))
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                } else if let txt = displayText {
                    Text(txt)
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                } else {
                    Text("—")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.primary.opacity(0.28))
                }
            }
            Spacer()
        }
        .padding(12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Golden Hour Card

    private var goldenHourCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(goldAccent)
                Text("Golden Hour")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(goldAccent.opacity(0.90))
                Spacer()
            }

            HStack(spacing: 0) {
                // Morning golden hour
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning")
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.45))
                    HStack(spacing: 4) {
                        timeText(solarTimes?.sunrise)
                        Text("→")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.35))
                        timeText(solarTimes?.goldenHourMorningEnd)
                    }
                }
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1, height: 36)
                Spacer()
                // Evening golden hour
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Evening")
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.45))
                    HStack(spacing: 4) {
                        timeText(solarTimes?.goldenHourEveningStart)
                        Text("→")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.35))
                        timeText(solarTimes?.sunset)
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(
            .regular.tint(colorScheme == .dark
                ? Color(red: 0.10, green: 0.08, blue: 0.01)
                : Color(red: 1.00, green: 0.92, blue: 0.65)),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    @ViewBuilder
    private func timeText(_ date: Date?) -> some View {
        if let d = date {
            Text(timeFormatter.string(from: d))
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(Color.primary)
        } else {
            Text("—")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.primary.opacity(0.28))
        }
    }

    // MARK: Day Length Card

    private var dayLengthCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(cyanAccent.opacity(0.15)).frame(width: 46, height: 46)
                Image(systemName: "sun.and.horizon.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(cyanAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Day Length")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(cyanAccent.opacity(0.90))
                Text(dayLengthText)
                    .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.primary)
            }
            Spacer()
            if let elev = sunElevation {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Elevation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.45))
                    let sign = elev >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", elev))°")
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(elev >= 0 ? goldAccent : purpleAccent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SunriseView()
    }
}
