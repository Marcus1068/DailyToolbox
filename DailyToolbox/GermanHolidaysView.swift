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
//  GermanHolidaysView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - German States

private struct GermanState: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }
}

private let germanStates: [GermanState] = [
    GermanState(code: "BW", name: "Baden-Württemberg"),
    GermanState(code: "BY", name: "Bayern"),
    GermanState(code: "BE", name: "Berlin"),
    GermanState(code: "BB", name: "Brandenburg"),
    GermanState(code: "HB", name: "Bremen"),
    GermanState(code: "HH", name: "Hamburg"),
    GermanState(code: "HE", name: "Hessen"),
    GermanState(code: "MV", name: "Mecklenburg-Vorpommern"),
    GermanState(code: "NI", name: "Niedersachsen"),
    GermanState(code: "NW", name: "Nordrhein-Westfalen"),
    GermanState(code: "RP", name: "Rheinland-Pfalz"),
    GermanState(code: "SL", name: "Saarland"),
    GermanState(code: "SN", name: "Sachsen"),
    GermanState(code: "ST", name: "Sachsen-Anhalt"),
    GermanState(code: "SH", name: "Schleswig-Holstein"),
    GermanState(code: "TH", name: "Thüringen"),
]

// MARK: - Models

private struct PublicHoliday: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let note: String

    var isPast: Bool { date < Calendar.current.startOfDay(for: Date()) }
    var isToday: Bool { Calendar.current.isDateInToday(date) }

    var daysLabel: String {
        let today = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "Heute" }
        if days < 0  { return "vor \(-days) Tagen" }
        if days == 1 { return "morgen" }
        return "in \(days) Tagen"
    }
}

private struct SchoolHoliday: Identifiable {
    let id = UUID()
    let name: String
    let start: Date
    let end: Date

    var durationDays: Int {
        (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var isActive: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return today >= Calendar.current.startOfDay(for: start) &&
               today <= Calendar.current.startOfDay(for: end)
    }

    var isPast: Bool { Calendar.current.startOfDay(for: end) < Calendar.current.startOfDay(for: Date()) }

    var formattedName: String {
        // "winterferien bayern 2025" → "Winterferien"
        let parts = name.components(separatedBy: " ")
        if let first = parts.first {
            return first.prefix(1).uppercased() + first.dropFirst()
        }
        return name
    }
}

// MARK: - Holiday Tab

private enum HolidayTab: String, CaseIterable {
    case publicHolidays = "Public Holidays"
    case schoolHolidays = "School Holidays"

    var icon: String {
        switch self {
        case .publicHolidays: return "flag.fill"
        case .schoolHolidays: return "backpack.fill"
        }
    }
    var localizedKey: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

// MARK: - Load State

private enum LoadState {
    case idle, loading, loaded, error(String)
}

// MARK: - View Model

@MainActor
private class HolidaysViewModel: ObservableObject {
    @Published var publicHolidays: [PublicHoliday] = []
    @Published var schoolHolidays: [SchoolHoliday] = []
    @Published var loadState: LoadState = .idle

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    func load(stateCode: String, year: Int) async {
        loadState = .loading
        publicHolidays = []
        schoolHolidays = []

        do {
            async let pub  = fetchPublicHolidays(stateCode: stateCode, year: year)
            async let sch  = fetchSchoolHolidays(stateCode: stateCode, year: year)
            let (p, s) = try await (pub, sch)
            publicHolidays = p.sorted { $0.date < $1.date }
            schoolHolidays = s.sorted { $0.start < $1.start }
            loadState = .loaded
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }

    private func fetchPublicHolidays(stateCode: String, year: Int) async throws -> [PublicHoliday] {
        let url = URL(string: "https://feiertage-api.de/api/?jahr=\(year)&nur_land=\(stateCode)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: [String: String]] else {
            return []
        }
        return dict.compactMap { name, info in
            guard let dateStr = info["datum"],
                  let date = isoFormatter.date(from: dateStr) else { return nil }
            let note = info["hinweis"] ?? ""
            return PublicHoliday(name: name, date: date, note: note)
        }
    }

    private func fetchSchoolHolidays(stateCode: String, year: Int) async throws -> [SchoolHoliday] {
        let url = URL(string: "https://ferien-api.de/api/v1/holidays/\(stateCode)/\(year)")!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct RawHoliday: Decodable {
            let start: String
            let end: String
            let name: String
        }

        let raw = try JSONDecoder().decode([RawHoliday].self, from: data)
        return raw.compactMap { h in
            guard let s = isoFormatter.date(from: String(h.start.prefix(10))),
                  let e = isoFormatter.date(from: String(h.end.prefix(10))) else { return nil }
            return SchoolHoliday(name: h.name, start: s, end: e)
        }
    }
}

// MARK: - Main View

struct GermanHolidaysView: View {

    @StateObject private var vm = HolidaysViewModel()

    @State private var selectedState: GermanState = germanStates[1] // Bayern default
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var tab: HolidayTab = .publicHolidays
    @State private var showStatePicker = false

    private let accent    = Color(red: 0.95, green: 0.78, blue: 0.22)   // German gold
    private let accentRed = Color(red: 0.85, green: 0.15, blue: 0.18)   // German red

    private var years: [Int] {
        let y = Calendar.current.component(.year, from: Date())
        return [y - 1, y, y + 1]
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        GlassEffectContainer { headerCard }
                        GlassEffectContainer { controlsCard }

                        switch vm.loadState {
                        case .idle:
                            idlePlaceholder
                        case .loading:
                            loadingCard
                        case .error(let msg):
                            GlassEffectContainer { errorCard(msg) }
                        case .loaded:
                            GlassEffectContainer { tabBar }
                            if tab == .publicHolidays {
                                publicHolidaysList
                            } else {
                                schoolHolidaysList
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("German Holidays")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showStatePicker) { statePickerSheet }
        .task { await vm.load(stateCode: selectedState.code, year: selectedYear) }
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
                Color(red:0.04,green:0.06,blue:0.16), Color(red:0.05,green:0.08,blue:0.20), Color(red:0.04,green:0.06,blue:0.18),
                Color(red:0.05,green:0.08,blue:0.20), Color(red:0.07,green:0.11,blue:0.28), Color(red:0.05,green:0.08,blue:0.22),
                Color(red:0.03,green:0.05,blue:0.14), Color(red:0.05,green:0.07,blue:0.18), Color(red:0.03,green:0.05,blue:0.14)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [Color(red:0.95,green:0.78,blue:0.22), Color(red:0.85,green:0.55,blue:0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("🇩🇪").font(.title2)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("German Holidays")
                    .font(.headline.weight(.bold)).foregroundStyle(.white)
                Text("Public holidays & school breaks")
                    .font(.caption).foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Controls Card

    private var controlsCard: some View {
        VStack(spacing: 12) {
            // State selector button
            Button { showStatePicker = true } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Federal State")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.50))
                        Text(selectedState.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
                .padding(14)
                .background(Color.white.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            // Year picker
            HStack(spacing: 8) {
                ForEach(years, id: \.self) { y in
                    let sel = selectedYear == y
                    Button {
                        withAnimation(.spring(response: 0.25)) { selectedYear = y }
                        Task { await vm.load(stateCode: selectedState.code, year: y) }
                    } label: {
                        Text(String(y))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(sel ? .black : .white.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(sel ? accent : Color.white.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(HolidayTab.allCases, id: \.self) { t in
                let sel = tab == t
                Button { withAnimation(.spring(response: 0.3)) { tab = t } } label: {
                    HStack(spacing: 7) {
                        Image(systemName: t.icon).font(.system(size: 12, weight: .semibold))
                        Text(t.localizedKey).font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(sel ? .black : .white.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(sel ? accent : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Public Holidays List

    private var publicHolidaysList: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                ForEach(Array(vm.publicHolidays.enumerated()), id: \.element.id) { idx, h in
                    publicHolidayRow(h, isLast: idx == vm.publicHolidays.count - 1)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder
    private func publicHolidayRow(_ h: PublicHoliday, isLast: Bool) -> some View {
        let weekday = h.date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))

        HStack(spacing: 14) {
            // Date badge
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(h.isToday ? accent.opacity(0.25)
                          : h.isPast ? Color.white.opacity(0.05)
                          : accent.opacity(0.12))
                VStack(spacing: 0) {
                    Text(h.date.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "de_DE"))))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(h.isPast ? .white.opacity(0.30) : accent.opacity(0.85))
                    Text(h.date.formatted(.dateTime.day()))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(h.isPast ? .white.opacity(0.30) : .white)
                }
                .padding(.vertical, 6)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(h.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(h.isPast ? .white.opacity(0.40) : .white)
                    .lineLimit(1)
                Text(weekday)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            if h.isToday {
                Text("Heute")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(accent, in: Capsule())
            } else if !h.isPast {
                Text(h.daysLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(h.isToday ? accent.opacity(0.10) : Color.clear)

        if !isLast {
            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.horizontal, 16)
        }
    }

    // MARK: - School Holidays List

    private var schoolHolidaysList: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                ForEach(Array(vm.schoolHolidays.enumerated()), id: \.element.id) { idx, h in
                    schoolHolidayRow(h, isLast: idx == vm.schoolHolidays.count - 1)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder
    private func schoolHolidayRow(_ h: SchoolHoliday, isLast: Bool) -> some View {
        let startStr = h.start.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
        let endStr   = h.end.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE")))

        HStack(spacing: 14) {
            // Color bar
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(h.isActive ? accent
                      : h.isPast ? Color.white.opacity(0.15)
                      : accentRed.opacity(0.80))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(h.formattedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(h.isPast ? .white.opacity(0.40) : .white)
                    Spacer()
                    if h.isActive {
                        Text("Läuft")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(accent, in: Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.40))
                    Text("\(startStr) – \(endStr)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(h.isPast ? 0.30 : 0.55))
                }
                Text("\(h.durationDays) Tage")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(h.isPast ? .white.opacity(0.25) : accent.opacity(0.75))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(h.isActive ? accent.opacity(0.08) : Color.clear)

        if !isLast {
            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Placeholder / Loading / Error

    private var idlePlaceholder: some View {
        GlassEffectContainer {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36))
                    .foregroundStyle(accent.opacity(0.50))
                Text("Select a state and year")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var loadingCard: some View {
        GlassEffectContainer {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(accent)
                    .scaleEffect(1.2)
                Text("Loading holidays…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder
    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(accentRed.opacity(0.80))
            Text("Could not load holidays")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.load(stateCode: selectedState.code, year: selectedYear) }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - State Picker Sheet

    private var statePickerSheet: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                List {
                    ForEach(germanStates) { state in
                        Button {
                            selectedState = state
                            showStatePicker = false
                            Task { await vm.load(stateCode: state.code, year: selectedYear) }
                        } label: {
                            HStack {
                                Text(state.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(state.code)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                                if state.code == selectedState.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(accent)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.07))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStatePicker = false }
                        .foregroundStyle(accent)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { GermanHolidaysView() }
}
