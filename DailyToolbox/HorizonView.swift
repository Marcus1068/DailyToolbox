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
//  HorizonView.swift
//  DailyToolbox
//

import SwiftUI
import CoreLocation

// MARK: - Location Manager

@Observable
@MainActor
final class HorizonLocationManager: NSObject {
    var altitude: Double         = 0.0
    var verticalAccuracy: Double = -1.0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isSearching: Bool        = true

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var accuracyLabel: String {
        if !isAuthorized         { return "No Permission" }
        if isSearching           { return "Searching…" }
        if verticalAccuracy < 0  { return "Unavailable" }
        return String(format: "±%.0f m", verticalAccuracy)
    }

    var accuracyColor: Color {
        if !isAuthorized || verticalAccuracy < 0 { return .red }
        if isSearching       { return .orange }
        if verticalAccuracy < 10 { return Color(red: 0.28, green: 0.95, blue: 0.58) }
        if verticalAccuracy < 20 { return .yellow }
        return .orange
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate       = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        authorizationStatus    = manager.authorizationStatus
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        isSearching = true
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
}

extension HorizonLocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last, loc.verticalAccuracy >= 0 else { return }
        // Dispatch to main actor to guarantee SwiftUI picks up @Observable changes
        Task { @MainActor [weak self] in
            self?.altitude         = loc.altitude
            self?.verticalAccuracy = loc.verticalAccuracy
            self?.isSearching      = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized { manager.startUpdatingLocation() }
        }
    }
}

// MARK: - Horizon Scene Illustration

private let horizonStars: [(x: Double, y: Double, op: Double, sz: Double)] = [
    (0.06, 0.10, 0.60, 2.0), (0.17, 0.22, 0.40, 1.5), (0.31, 0.07, 0.70, 2.5),
    (0.46, 0.17, 0.45, 2.0), (0.60, 0.09, 0.65, 1.5), (0.72, 0.26, 0.50, 2.0),
    (0.83, 0.13, 0.55, 2.5), (0.93, 0.20, 0.40, 1.5)
]

private struct HorizonSceneView: View {
    let distance: Double
    let unit: String

    var body: some View {
        GeometryReader { geo in
            let w  = geo.size.width
            let h  = geo.size.height
            let hy = h * 0.53   // horizon Y

            ZStack(alignment: .topLeading) {

                // Sky gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.12, blue: 0.42),
                        Color(red: 0.10, green: 0.28, blue: 0.65).opacity(0.55)
                    ],
                    startPoint: .top, endPoint: .center
                )

                // Ocean gradient
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.18, blue: 0.48).opacity(0.85),
                            Color(red: 0.01, green: 0.07, blue: 0.22)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: h - hy + 12)
                }

                // Stars
                ForEach(horizonStars.indices, id: \.self) { i in
                    let s = horizonStars[i]
                    Circle()
                        .fill(Color.primary.opacity(s.op))
                        .frame(width: s.sz, height: s.sz)
                        .position(x: s.x * w, y: s.y * h * 0.95)
                }

                // Horizon curve
                Path { p in
                    p.move(to: CGPoint(x: 0, y: hy + 8))
                    p.addCurve(
                        to: CGPoint(x: w, y: hy - 8),
                        control1: CGPoint(x: w * 0.30, y: hy - 14),
                        control2: CGPoint(x: w * 0.70, y: hy + 14)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.20), Color.primary.opacity(0.82), Color.primary.opacity(0.20)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )

                // Observer: vertical height line + eye icon
                let eyeX: Double = 46
                let eyeY: Double = h * 0.30

                Path { p in
                    p.move(to: CGPoint(x: eyeX, y: hy - 2))
                    p.addLine(to: CGPoint(x: eyeX, y: eyeY + 13))
                }
                .stroke(Color.primary.opacity(0.38), lineWidth: 1.0)

                // Dashed sight line from eye to horizon
                Path { p in
                    p.move(to: CGPoint(x: eyeX, y: eyeY))
                    p.addLine(to: CGPoint(x: w - 26, y: hy))
                }
                .stroke(Color.primary.opacity(0.52),
                        style: StrokeStyle(lineWidth: 1.3, dash: [7, 5]))

                Image(systemName: "eye.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .position(x: eyeX, y: eyeY)

                // Glowing horizon dot
                Circle()
                    .fill(Color(red: 0.55, green: 0.88, blue: 1.00))
                    .frame(width: 9, height: 9)
                    .shadow(color: Color(red: 0.55, green: 0.88, blue: 1.00).opacity(0.80), radius: 7)
                    .position(x: w - 26, y: hy)

                // Distance badge
                if distance > 0 {
                    Text(String(format: "%.2f \(unit)", distance))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.12), in: Capsule())
                        .position(x: w - 54, y: h - 16)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4), value: distance)
                }
            }
        }
        .frame(height: 135)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Main View

struct HorizonView: View {

    @State  private var locationManager = HorizonLocationManager()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    // Two AppStorage vars — that's all we need.
    // eyeLevelMeters is ALWAYS in metres. Display converts on the fly.
    @AppStorage("horizonView.eyeLevelMeters") private var eyeLevelMeters: Double = 0.0
    @AppStorage("horizonView.useMiles")       private var showMiles:      Bool   = false

    // MARK: Adaptive colors

    private var blueAccent: Color {
        colorScheme == .dark ? Color(red: 0.45, green: 0.74, blue: 1.00)
                             : Color(red: 0.08, green: 0.42, blue: 0.88)
    }
    private var greenAccent: Color {
        colorScheme == .dark ? Color(red: 0.28, green: 0.88, blue: 0.65)
                             : Color(red: 0.05, green: 0.58, blue: 0.38)
    }
    private var goldAccent: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.82, blue: 0.22)
                             : Color(red: 0.68, green: 0.48, blue: 0.00)
    }
    private var cyanAccent: Color {
        colorScheme == .dark ? Color(red: 0.55, green: 0.88, blue: 1.00)
                             : Color(red: 0.08, green: 0.46, blue: 0.78)
    }
    private var glassTintBlue: Color {
        colorScheme == .dark ? Color(red: 0.03, green: 0.10, blue: 0.38)
                             : Color(red: 0.60, green: 0.78, blue: 1.00)
    }
    private var glassTintGold: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.08, blue: 0.01)
                             : Color(red: 1.00, green: 0.90, blue: 0.60)
    }

    // MARK: Computed

    private var altitude:        Double { locationManager.altitude }
    private var distanceKm:      Double { ComputeHorizon(eyeLevel: eyeLevelMeters, altitude: altitude).viewDistance }
    private var distanceDisplay: Double { showMiles ? distanceKm * 0.621371 : distanceKm }
    private var unitLabel:       String { showMiles ? "mi" : "km" }
    private var formulaConstant: String  { showMiles ? "1.22" : "3.57" }
    private var eyeLevelUnitLabel: String { showMiles ? "ft" : "m" }

    /// Eye level value to display — metres or feet, zero shows "—"
    private var eyeLevelDisplay: String {
        guard eyeLevelMeters > 0 else { return "—" }
        let v = showMiles ? eyeLevelMeters * 3.28084 : eyeLevelMeters
        return String(format: "%.2f", v)
    }

    // MARK: Actions

    private func adjustEyeLevel(by delta: Double) {
        // delta is in the current display unit (0.10 m or 0.10 ft); convert step to metres
        let stepMetres = showMiles ? delta / 3.28084 : delta
        let maxMetres  = 5.0
        eyeLevelMeters = max(0.0, min(maxMetres,
            ((eyeLevelMeters + stepMetres) * 1000).rounded() / 1000))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        gpsAltitudeCard
                        HorizonSceneView(distance: distanceDisplay, unit: unitLabel)
                        eyeLevelCard
                        resultCard
                        formulaCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("Horizon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear  { locationManager.start() }
        .onDisappear { locationManager.stop() }
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
                Color(red: 0.02, green: 0.06, blue: 0.22),
                Color(red: 0.03, green: 0.10, blue: 0.32),
                Color(red: 0.02, green: 0.08, blue: 0.24),
                Color(red: 0.02, green: 0.09, blue: 0.28),
                Color(red: 0.04, green: 0.14, blue: 0.40),
                Color(red: 0.02, green: 0.10, blue: 0.28),
                Color(red: 0.01, green: 0.05, blue: 0.18),
                Color(red: 0.02, green: 0.10, blue: 0.26),
                Color(red: 0.01, green: 0.06, blue: 0.20)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.40, green: 0.70, blue: 1.0).opacity(0.14))
                    .frame(width: 50, height: 50)
                Image(systemName: "binoculars.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.50, green: 0.78, blue: 1.0),
                                     Color(red: 0.22, green: 0.52, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Horizon Calculator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("GPS altitude + eye level → distance to horizon")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: GPS Altitude Card

    private var gpsAltitudeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(locationManager.accuracyColor.opacity(0.14))
                    .frame(width: 46, height: 46)
                Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(locationManager.accuracyColor)
                    .symbolEffect(.pulse, isActive: locationManager.isSearching)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("GPS Altitude")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(blueAccent.opacity(0.90))

                Group {
                    if locationManager.isSearching {
                        Text("—  m")
                    } else {
                        Text(String(format: "%.2f m", altitude))
                    }
                }
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35), value: altitude)

                Text(LocalizedStringKey(locationManager.accuracyLabel))
                    .font(.caption2)
                    .foregroundStyle(locationManager.accuracyColor.opacity(0.78))
                if locationManager.authorizationStatus == .denied ||
                    locationManager.authorizationStatus == .restricted {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            Task { @MainActor in await UIApplication.shared.open(url) }
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(blueAccent)
                }
            }

            Spacer()

            // Altitude bar gauge (0–500 m → 0–50 px)
            VStack(spacing: 4) {
                Text("ASL")
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.30))
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.07))
                        .frame(width: 8, height: 50)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [blueAccent.opacity(0.80), cyanAccent],
                                startPoint: .bottom, endPoint: .top
                            )
                        )
                        .frame(width: 8, height: max(2, min(50, altitude / 10)))
                        .animation(.spring(response: 0.5), value: altitude)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            .regular.tint(glassTintBlue),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    // MARK: Eye Level Card

    private var eyeLevelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(greenAccent.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: "eye")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(greenAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Eye Level")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(greenAccent.opacity(0.90))
                    Text("Your eyes above ground")
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.35))
                }
                Spacer()
                // ± step buttons
                HStack(spacing: 8) {
                    Button { adjustEyeLevel(by: -0.10) } label: {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.glass)

                    Button { adjustEyeLevel(by: +0.10) } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.glass)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(eyeLevelDisplay)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35), value: eyeLevelMeters)
                Text(eyeLevelUnitLabel)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.40))
            }
            .padding(.leading, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Result Card

    private var resultCard: some View {
        let shareString = "Horizon: \(String(format: "%.2f", distanceDisplay)) \(unitLabel) · Eye level: \(eyeLevelDisplay) \(eyeLevelUnitLabel)"
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Horizon Distance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(goldAccent.opacity(0.90))
                Spacer()
                Picker("", selection: $showMiles) {
                    Text("km").tag(false)
                    Text("mi").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(distanceDisplay.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: 54, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldAccent, goldAccent.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: distanceDisplay)
                Text(unitLabel)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.52))
                    .padding(.bottom, 5)
                    .contentTransition(.identity)
                    .animation(.spring(response: 0.3), value: showMiles)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        UIPasteboard.general.string = shareString
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Copy")
                    ShareLink(item: shareString) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.tint(glassTintGold),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: Formula Card

    private var formulaCard: some View {
        let altStr  = String(format: "%.2f", altitude)
        let eyeStr  = String(format: "%.2f", eyeLevelMeters)
        let distStr = String(format: "%.4f", distanceDisplay)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "function")
                    .font(.caption.weight(.semibold))
                Text("Formula")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.52))

            Text(showMiles
                 ? "d = 1.22 × √( altitude + eye level )"
                 : "d = 3.57 × √( altitude + eye level )")
                .font(.system(.subheadline, design: .monospaced).weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.88))

            Divider().overlay(Color.primary.opacity(0.10))

            Text("d = \(formulaConstant) × √( \(altStr) + \(eyeStr) ) = \(distStr) \(unitLabel)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(cyanAccent.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HorizonView()
    }
}
