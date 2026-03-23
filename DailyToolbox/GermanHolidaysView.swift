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
//  GermanHolidaysView.swift
//  DailyToolbox
//

import EventKit
import SwiftUI

// MARK: - Country Model

private struct HolidayCountry: Identifiable, Hashable {
    let code: String
    let name: String
    let flag: String
    var id: String { code }
}

private let holidayCountries: [HolidayCountry] = [
    HolidayCountry(code: "DE", name: "Germany",     flag: "🇩🇪"),
    HolidayCountry(code: "AT", name: "Austria",     flag: "🇦🇹"),
    HolidayCountry(code: "CH", name: "Switzerland", flag: "🇨🇭"),
    HolidayCountry(code: "FR", name: "France",      flag: "🇫🇷"),
    HolidayCountry(code: "IT", name: "Italy",       flag: "🇮🇹"),
    HolidayCountry(code: "DK", name: "Denmark",     flag: "🇩🇰"),
]

private let countryRegions: [String: [(code: String, name: String)]] = [
    "DE": [("BW","Baden-Württemberg"),("BY","Bayern"),("BE","Berlin"),("BB","Brandenburg"),
           ("HB","Bremen"),("HH","Hamburg"),("HE","Hessen"),("MV","Mecklenburg-Vorpommern"),
           ("NI","Niedersachsen"),("NW","Nordrhein-Westfalen"),("RP","Rheinland-Pfalz"),
           ("SL","Saarland"),("SN","Sachsen"),("ST","Sachsen-Anhalt"),
           ("SH","Schleswig-Holstein"),("TH","Thüringen")],
    "AT": [("1","Burgenland"),("2","Kärnten"),("3","Niederösterreich"),("4","Oberösterreich"),
           ("5","Salzburg"),("6","Steiermark"),("7","Tirol"),("8","Vorarlberg"),("9","Wien")],
    "CH": [("AG","Aargau"),("AR","Appenzell Ausserrhoden"),("AI","Appenzell Innerrhoden"),
           ("BL","Basel-Landschaft"),("BS","Basel-Stadt"),("BE","Bern"),("FR","Freiburg"),
           ("GE","Genf"),("GL","Glarus"),("GR","Graubünden"),("JU","Jura"),("LU","Luzern"),
           ("NE","Neuenburg"),("NW","Nidwalden"),("OW","Obwalden"),("SG","St. Gallen"),
           ("SH","Schaffhausen"),("SZ","Schwyz"),("SO","Solothurn"),("TG","Thurgau"),
           ("TI","Tessin"),("UR","Uri"),("VD","Waadt"),("VS","Wallis"),("ZG","Zug"),("ZH","Zürich")],
    "FR": [("ARA","Auvergne-Rhône-Alpes"),("BFC","Bourgogne-Franche-Comté"),("BRE","Bretagne"),
           ("CVL","Centre-Val de Loire"),("COR","Corse"),("GES","Grand Est"),
           ("HDF","Hauts-de-France"),("IDF","Île-de-France"),("NOR","Normandie"),
           ("NAQ","Nouvelle-Aquitaine"),("OCC","Occitanie"),("PDL","Pays de la Loire"),
           ("PAC","Provence-Alpes-Côte d'Azur")],
    "IT": [("65","Abruzzen"),("77","Basilikata"),("78","Kalabrien"),("72","Kampanien"),
           ("45","Emilia-Romagna"),("36","Friaul-Julisch Venetien"),("62","Latium"),
           ("42","Ligurien"),("25","Lombardei"),("57","Marken"),("67","Molise"),
           ("21","Piemont"),("75","Apulien"),("88","Sardinien"),("82","Sizilien"),
           ("52","Toskana"),("32","Trentino-Südtirol"),("55","Umbrien"),
           ("23","Aostatal"),("34","Venetien")],
    "DK": [("84","Hauptstadtregion"),("82","Mitteljütland"),("81","Nordjütland"),
           ("85","Seeland"),("83","Süddänemark")],
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
        if days == 0 { return NSLocalizedString("Heute", comment: "Today") }
        if days < 0  { return String(format: NSLocalizedString("vor %lld Tagen", comment: "N days ago"), -days) }
        if days == 1 { return NSLocalizedString("morgen", comment: "Tomorrow") }
        return String(format: NSLocalizedString("in %lld Tagen", comment: "In N days"), days)
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
        let parts = name.components(separatedBy: " ")
        if let first = parts.first {
            return first.prefix(1).uppercased() + first.dropFirst()
        }
        return name
    }
}

/// A suggested bridge-day opportunity: take one leave day to create a 4-day weekend.
private struct BridgeDaySuggestion: Identifiable {
    /// ISO date string of the leave day — used as stable storage key.
    let id: String
    let holidayName: String
    let holidayDate: Date
    /// The single leave day to take (Friday after Thursday holiday, or Monday before Tuesday holiday).
    let leaveDay: Date
    /// First day of the consecutive 4-day window.
    let windowStart: Date
    /// Last day of the consecutive 4-day window.
    let windowEnd: Date

    var windowDescription: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM."
        fmt.locale = Locale(identifier: "de_DE")
        let endFmt = DateFormatter()
        endFmt.dateFormat = "dd.MM.yyyy"
        endFmt.locale = Locale(identifier: "de_DE")
        return "\(fmt.string(from: windowStart))–\(endFmt.string(from: windowEnd))"
    }
}

// MARK: - Holiday Tab

private enum HolidayTab: String, CaseIterable {
    case publicHolidays = "Public Holidays"
    case schoolHolidays = "School Holidays"
    case bridgeDays     = "Bridge Days"

    var icon: String {
        switch self {
        case .publicHolidays: return "flag.fill"
        case .schoolHolidays: return "backpack.fill"
        case .bridgeDays:     return "airplane.departure"
        }
    }
    var localizedKey: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

// MARK: - Load State

private enum LoadState {
    case idle, loading, loaded, error(String)
}

// MARK: - View Model

@Observable @MainActor
private class HolidaysViewModel {
    var publicHolidays: [PublicHoliday] = []
    var schoolHolidays: [SchoolHoliday] = []
    var loadState: LoadState = .idle

    func load(countryCode: String, stateCode: String, year: Int) async {
        loadState = .loading
        publicHolidays = []
        schoolHolidays = []

        let lang = (Locale.current.language.languageCode?.identifier ?? "en").uppercased()

        do {
            publicHolidays = try await fetchPublicHolidays(
                countryCode: countryCode, stateCode: stateCode,
                languageCode: lang, year: year
            ).sorted { $0.date < $1.date }
        } catch {
            loadState = .error(error.localizedDescription)
            return
        }

        if countryCode == "DE" {
            do {
                schoolHolidays = try await fetchSchoolHolidays(
                    stateCode: stateCode, languageCode: lang, year: year
                ).sorted { $0.start < $1.start }
            } catch {
                // School holidays are best-effort; public holidays are still shown
            }
        }

        loadState = .loaded
    }

    private func fetchPublicHolidays(countryCode: String, stateCode: String, languageCode: String, year: Int) async throws -> [PublicHoliday] {
        var urlStr = "https://openholidaysapi.org/PublicHolidays?countryIsoCode=\(countryCode)&languageIsoCode=\(languageCode)&validFrom=\(year)-01-01&validTo=\(year)-12-31"
        if !stateCode.isEmpty {
            urlStr += "&subdivisionCode=\(countryCode)-\(stateCode)"
        }
        let url = URL(string: urlStr)!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct RawHoliday: Decodable {
            let startDate: String
            let name: [LocalizedName]
            struct LocalizedName: Decodable {
                let language: String
                let text: String
            }
        }

        let dateStrategy = Date.ISO8601FormatStyle().year().month().day()
        let raw = try JSONDecoder().decode([RawHoliday].self, from: data)
        return raw.compactMap { h in
            guard let date = try? Date(h.startDate, strategy: dateStrategy),
                  let name = h.name.first?.text else { return nil }
            return PublicHoliday(name: name, date: date, note: "")
        }
    }

    private func fetchSchoolHolidays(stateCode: String, languageCode: String, year: Int) async throws -> [SchoolHoliday] {
        let url = URL(string: "https://openholidaysapi.org/SchoolHolidays?countryIsoCode=DE&subdivisionCode=DE-\(stateCode)&languageIsoCode=\(languageCode)&validFrom=\(year)-01-01&validTo=\(year)-12-31")!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct RawHoliday: Decodable {
            let startDate: String
            let endDate: String
            let name: [LocalizedName]
            struct LocalizedName: Decodable {
                let language: String
                let text: String
            }
        }

        let dateStrategy = Date.ISO8601FormatStyle().year().month().day()
        let raw = try JSONDecoder().decode([RawHoliday].self, from: data)
        return raw.compactMap { h in
            guard let start = try? Date(h.startDate, strategy: dateStrategy),
                  let end = try? Date(h.endDate, strategy: dateStrategy),
                  let name = h.name.first?.text else { return nil }
            return SchoolHoliday(name: name, start: start, end: end)
        }
    }
}

// MARK: - Main View

struct GermanHolidaysView: View {

    @State private var vm = HolidaysViewModel()

    @AppStorage("germanHolidays.stateCode")    private var savedStateCode:     String = "BY"
    @AppStorage("germanHolidays.year")         private var savedYear:           Int    = Calendar.current.component(.year, from: Date())
    @AppStorage("germanHolidays.leaveDays")    private var leaveDaysTotal:      Int    = 30
    @AppStorage("germanHolidays.bookedBridges")private var bookedBridgesStr:    String = ""
    @AppStorage("holidays.selectedCountry")    private var savedCountry:        String = "DE"

    private var currentRegions: [(code: String, name: String)] {
        countryRegions[savedCountry] ?? []
    }

    private var selectedRegion: (code: String, name: String) {
        currentRegions.first { $0.code == savedStateCode }
            ?? currentRegions.first
            ?? (code: "", name: "")
    }

    private var currentCountry: HolidayCountry {
        holidayCountries.first { $0.code == savedCountry } ?? holidayCountries[0]
    }

    private var availableTabs: [HolidayTab] {
        savedCountry == "DE" ? HolidayTab.allCases : [.publicHolidays]
    }

    @State private var tab: HolidayTab = .publicHolidays
    @State private var showStatePicker  = false
    @State private var showExportConfirm = false
    @State private var showExportResult  = false
    @State private var exportCount       = 0
    @State private var exportError: String? = nil

    private let accent    = Color(red: 0.95, green: 0.78, blue: 0.22)
    private let accentRed = Color(red: 0.85, green: 0.15, blue: 0.18)
    private let bridgeGreen = Color(red: 0.22, green: 0.88, blue: 0.55)

    private static let isoKey: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "de_DE"); return f
    }()

    private var years: [Int] {
        let y = Calendar.current.component(.year, from: Date())
        return [y - 1, y, y + 1]
    }

    // MARK: - Bridge Day Logic

    private var bookedSet: Set<String> {
        Set(bookedBridgesStr.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private var bridgeSuggestions: [BridgeDaySuggestion] {
        guard case .loaded = vm.loadState else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "de_DE")
        var result: [BridgeDaySuggestion] = []

        for holiday in vm.publicHolidays {
            let weekday = cal.component(.weekday, from: holiday.date)
            // weekday: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat

            if weekday == 5 {
                // Thursday holiday → take Friday → Th+Fr+Sa+Su
                guard let leaveDay = cal.date(byAdding: .day, value: 1, to: holiday.date),
                      let winEnd   = cal.date(byAdding: .day, value: 3, to: holiday.date)
                else { continue }
                guard !isInSchoolHolidays(leaveDay) else { continue }
                let key = Self.isoKey.string(from: leaveDay)
                result.append(BridgeDaySuggestion(
                    id: key, holidayName: holiday.name, holidayDate: holiday.date,
                    leaveDay: leaveDay, windowStart: holiday.date, windowEnd: winEnd
                ))

            } else if weekday == 3 {
                // Tuesday holiday → take Monday → Sa+Su+Mo+Tu
                guard let leaveDay   = cal.date(byAdding: .day, value: -1, to: holiday.date),
                      let winStart   = cal.date(byAdding: .day, value: -3, to: holiday.date)
                else { continue }
                guard !isInSchoolHolidays(leaveDay) else { continue }
                let key = Self.isoKey.string(from: leaveDay)
                result.append(BridgeDaySuggestion(
                    id: key, holidayName: holiday.name, holidayDate: holiday.date,
                    leaveDay: leaveDay, windowStart: winStart, windowEnd: holiday.date
                ))
            }
        }
        return result.sorted { $0.leaveDay < $1.leaveDay }
    }

    private func isInSchoolHolidays(_ date: Date) -> Bool {
        let d = Calendar.current.startOfDay(for: date)
        return vm.schoolHolidays.contains { h in
            d >= Calendar.current.startOfDay(for: h.start) &&
            d <= Calendar.current.startOfDay(for: h.end)
        }
    }

    private var leaveDaysUsed: Int {
        bookedSet.intersection(bridgeSuggestions.map(\.id)).count
    }

    private var leaveDaysRemaining: Int { leaveDaysTotal - leaveDaysUsed }

    private func toggleBridge(_ s: BridgeDaySuggestion) {
        var set = bookedSet
        if set.contains(s.id) { set.remove(s.id) } else { set.insert(s.id) }
        bookedBridgesStr = set.joined(separator: ",")
    }

    private func exportToCalendar() async {
        let store = EKEventStore()
        do {
            guard try await store.requestFullAccessToEvents() else {
                exportError = NSLocalizedString(
                    "Calendar access denied. Please allow access in Settings.",
                    comment: "")
                showExportResult = true
                return
            }
        } catch {
            exportError = error.localizedDescription
            showExportResult = true
            return
        }
        let cal = Calendar.current
        var added = 0
        for h in vm.publicHolidays {
            let event       = EKEvent(eventStore: store)
            event.title     = h.name
            event.notes     = "\(selectedRegion.name) · \(savedYear) · DailyToolbox"
            event.isAllDay  = true
            let comps       = cal.dateComponents([.year, .month, .day], from: h.date)
            guard let day   = cal.date(from: comps) else { continue }
            event.startDate = day
            event.endDate   = day
            event.calendar  = store.defaultCalendarForNewEvents
            try? store.save(event, span: .thisEvent)
            added += 1
        }
        exportCount = added
        exportError = nil
        showExportResult = true
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
                            if availableTabs.count > 1 {
                                GlassEffectContainer { tabBar }
                            }
                            switch tab {
                            case .publicHolidays: publicHolidaysList
                            case .schoolHolidays: schoolHolidaysList
                            case .bridgeDays:     bridgeDaysContent
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Holidays")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .sheet(isPresented: $showStatePicker) { statePickerSheet }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if case .loaded = vm.loadState, !vm.publicHolidays.isEmpty {
                    Button { showExportConfirm = true } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .accessibilityLabel("Export to Calendar")
                }
            }
        }
        .confirmationDialog(
            "Add \(vm.publicHolidays.count) holidays for \(selectedRegion.name) \(String(savedYear)) to your Calendar?",
            isPresented: $showExportConfirm,
            titleVisibility: .visible
        ) {
            Button("Add to Calendar") { Task { await exportToCalendar() } }
            Button("Cancel", role: .cancel) { }
        }
        .alert(
            exportError == nil ? "Export Complete" : "Export Failed",
            isPresented: $showExportResult
        ) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            if let err = exportError {
                Text(err)
            } else {
                Text("\(exportCount) holidays added to your Calendar.")
            }
        }
        .task { await vm.load(countryCode: savedCountry, stateCode: selectedRegion.code, year: savedYear) }
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
                Text(currentCountry.flag).font(.title2)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(currentCountry.name + " Holidays")
                    .font(.headline.weight(.bold)).foregroundStyle(Color.primary)
                Text("Public holidays & regional celebrations")
                    .font(.caption).foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Country Picker

    private var countryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(holidayCountries) { country in
                    Button {
                        guard country.code != savedCountry else { return }
                        let newState = countryRegions[country.code]?.first?.code ?? ""
                        savedCountry = country.code
                        savedStateCode = newState
                        if country.code != "DE" { tab = .publicHolidays }
                        Task { await vm.load(countryCode: country.code, stateCode: newState, year: savedYear) }
                    } label: {
                        HStack(spacing: 6) {
                            Text(country.flag).font(.title3)
                            Text(country.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(savedCountry == country.code ? .black : Color.primary.opacity(0.75))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            savedCountry == country.code ? accent : Color.primary.opacity(0.10),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Controls Card

    private var controlsCard: some View {
        VStack(spacing: 12) {
            // Country picker
            countryPicker

            // Region selector button
            Button { showStatePicker = true } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(savedCountry == "DE" ? "Federal State" : "Region")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.50))
                        Text(selectedRegion.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
                .padding(14)
                .background(Color.primary.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Year picker
            HStack(spacing: 8) {
                ForEach(years, id: \.self) { y in
                    let sel = savedYear == y
                    Button {
                        withAnimation(.spring(response: 0.25)) { savedYear = y }
                        Task { await vm.load(countryCode: savedCountry, stateCode: selectedRegion.code, year: y) }
                    } label: {
                        Text(String(y))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(sel ? accent : Color.primary.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Leave days input row — only relevant for Germany (bridge days)
            if savedCountry == "DE" {
                HStack(spacing: 12) {
                    Image(systemName: "suitcase.rolling.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(bridgeGreen)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Annual Leave Days")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.50))
                        Text("\(leaveDaysUsed) used · \(max(0, leaveDaysRemaining)) remaining")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(leaveDaysRemaining < 0
                                ? accentRed.opacity(0.90)
                                : Color.primary.opacity(0.45))
                            .animation(.easeInOut(duration: 0.2), value: leaveDaysUsed)
                    }

                    Spacer()

                    // Stepper-style +/- with text field in the middle
                    HStack(spacing: 0) {
                        Button {
                            if leaveDaysTotal > 1 {
                                leaveDaysTotal -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.primary.opacity(0.65))
                                .frame(width: 32, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Decrease leave days")

                        Text(leaveDaysTotal, format: .number)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.primary)
                            .frame(width: 44, height: 34)

                        Button {
                            if leaveDaysTotal < 365 {
                                leaveDaysTotal += 1
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.primary.opacity(0.65))
                                .frame(width: 32, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Increase leave days")
                    }
                    .background(Color.primary.opacity(0.09),
                                in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(14)
                .background(Color.primary.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(availableTabs, id: \.self) { t in
                let sel = tab == t
                Button { withAnimation(.spring(response: 0.3)) { tab = t } } label: {
                    HStack(spacing: 6) {
                        Image(systemName: t.icon).font(.system(size: 11, weight: .semibold))
                        if t == .bridgeDays, case .loaded = vm.loadState, !bridgeSuggestions.isEmpty {
                            Text("\(bridgeSuggestions.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(sel ? accent : Color.primary.opacity(0.55))
                        }
                    }
                    .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(sel ? accent : Color.primary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Public Holidays List

    private var publicHolidaysList: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                ForEach(Array(vm.publicHolidays.enumerated()), id: \.element.id) { idx, h in
                    publicHolidayRow(h, isLast: idx == vm.publicHolidays.count - 1)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
        }
    }

    @ViewBuilder
    private func publicHolidayRow(_ h: PublicHoliday, isLast: Bool) -> some View {
        let weekday = h.date.formatted(.dateTime.weekday(.wide).locale(Locale.current))

        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(h.isToday ? accent.opacity(0.25)
                          : h.isPast ? Color.primary.opacity(0.05)
                          : accent.opacity(0.12))
                VStack(spacing: 0) {
                    Text(h.date.formatted(.dateTime.month(.abbreviated).locale(Locale.current)))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(h.isPast ? Color.primary.opacity(0.30) : accent.opacity(0.85))
                    Text(h.date.formatted(.dateTime.day()))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(h.isPast ? Color.primary.opacity(0.30) : Color.primary)
                }
                .padding(.vertical, 6)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(h.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(h.isPast ? Color.primary.opacity(0.40) : Color.primary)
                    .lineLimit(1)
                Text(weekday)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.45))
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
                    .foregroundStyle(Color.primary.opacity(0.45))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(h.isToday ? accent.opacity(0.10) : Color.clear)

        if !isLast {
            Divider().padding(.horizontal, 16)
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
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
        }
    }

    @ViewBuilder
    private func schoolHolidayRow(_ h: SchoolHoliday, isLast: Bool) -> some View {
        let startStr = h.start.formatted(.dateTime.day().month(.abbreviated).locale(Locale.current))
        let endStr   = h.end.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale.current))

        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(h.isActive ? accent
                      : h.isPast ? Color.primary.opacity(0.15)
                      : accentRed.opacity(0.80))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(h.formattedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(h.isPast ? Color.primary.opacity(0.40) : Color.primary)
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
                        .foregroundStyle(Color.primary.opacity(0.40))
                    Text("\(startStr) – \(endStr)")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(h.isPast ? 0.30 : 0.55))
                }
                Text("\(h.durationDays) Tage")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(h.isPast ? Color.primary.opacity(0.25) : accent.opacity(0.75))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(h.isActive ? accent.opacity(0.08) : Color.clear)

        if !isLast {
            Divider().padding(.horizontal, 16)
        }
    }

    // MARK: - Bridge Days Content

    private var bridgeDaysContent: some View {
        VStack(spacing: 12) {
            // Explanation header
            HStack(spacing: 12) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(bridgeGreen)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bridge Day Calculator")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text("Take 1 leave day next to a Tuesday or Thursday holiday to get 4 days off in a row.")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(14)
            .glassEffect(.regular.tint(bridgeGreen.opacity(0.06)),
                         in: RoundedRectangle(cornerRadius: 18))

            // Summary card
            bridgeSummaryCard

            if bridgeSuggestions.isEmpty {
                GlassEffectContainer {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 36))
                            .foregroundStyle(bridgeGreen.opacity(0.50))
                        Text("No bridge day opportunities found")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.50))
                        Text("No public holidays fall on Tuesday or Thursday outside school holiday periods.")
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.35))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
                }
            } else {
                GlassEffectContainer {
                    VStack(spacing: 0) {
                        ForEach(Array(bridgeSuggestions.enumerated()), id: \.element.id) { idx, s in
                            bridgeDayRow(s, isLast: idx == bridgeSuggestions.count - 1)
                        }
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
                }
            }
        }
    }

    private var bridgeSummaryCard: some View {
        HStack(spacing: 0) {
            summaryPill(value: leaveDaysTotal,              label: "Total",     color: Color.primary.opacity(0.70))
            Divider().frame(height: 32).padding(.horizontal, 4)
            summaryPill(value: leaveDaysUsed,               label: "Booked",    color: accentRed.opacity(0.80))
            Divider().frame(height: 32).padding(.horizontal, 4)
            summaryPill(value: max(0, leaveDaysRemaining),  label: "Remaining", color: bridgeGreen)
            Divider().frame(height: 32).padding(.horizontal, 4)
            summaryPill(value: bridgeSuggestions.count,     label: "Options",   color: accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .glassEffect(.regular.tint(bridgeGreen.opacity(0.08)),
                     in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func summaryPill(value: Int, label: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func bridgeDayRow(_ s: BridgeDaySuggestion, isLast: Bool) -> some View {
        let booked = bookedSet.contains(s.id)
        let leaveFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "EE dd.MM."
            f.locale = Locale.current
            return f
        }()

        Button { withAnimation(.spring(response: 0.25)) { toggleBridge(s) } } label: {
            HStack(spacing: 14) {
                // Date badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(booked ? bridgeGreen.opacity(0.20) : Color.primary.opacity(0.06))
                    VStack(spacing: 0) {
                        Text(s.holidayDate.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "de_DE"))))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(booked ? bridgeGreen.opacity(0.90) : accent.opacity(0.80))
                        Text(s.holidayDate.formatted(.dateTime.day()))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.vertical, 6)
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(s.holidayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Label {
                            Text("Take \(leaveFmt.string(from: s.leaveDay))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(booked ? bridgeGreen : Color.primary.opacity(0.55))
                        } icon: {
                            Image(systemName: "suitcase.rolling.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(booked ? bridgeGreen : Color.primary.opacity(0.40))
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.primary.opacity(0.35))
                        Text("4 days off: \(s.windowDescription)")
                            .font(.caption2)
                            .foregroundStyle(Color.primary.opacity(0.45))
                    }
                }

                Spacer()

                // Checkmark toggle
                ZStack {
                    Circle()
                        .fill(booked ? bridgeGreen : Color.primary.opacity(0.08))
                        .frame(width: 28, height: 28)
                    if booked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .animation(.spring(response: 0.25), value: booked)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(booked ? bridgeGreen.opacity(0.07) : Color.clear)
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider().padding(.horizontal, 16)
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
                    .foregroundStyle(Color.primary.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
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
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
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
                .foregroundStyle(Color.primary.opacity(0.70))
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.35))
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.load(countryCode: savedCountry, stateCode: selectedRegion.code, year: savedYear) }
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - State Picker Sheet

    private var statePickerSheet: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                List {
                    ForEach(currentRegions, id: \.code) { region in
                        Button {
                            savedStateCode = region.code
                            showStatePicker = false
                            Task { await vm.load(countryCode: savedCountry, stateCode: region.code, year: savedYear) }
                        } label: {
                            HStack {
                                Text(region.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(region.code)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.primary.opacity(0.45))
                                if region.code == savedStateCode {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(accent)
                                }
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.07))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Region")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
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
