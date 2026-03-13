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
//  CalendarCalculationView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Date Helpers

private func nextChristmas() -> Date {
    let cal   = Calendar.current
    let today = Date()
    let year  = cal.component(.year,  from: today)
    let month = cal.component(.month, from: today)
    let day   = cal.component(.day,   from: today)
    var comps = DateComponents()
    comps.month = 12
    comps.day   = 24
    comps.year  = (month == 12 && day > 23) ? year + 1 : year
    return cal.date(from: comps)!
}

private func computeEaster(for year: Int) -> Date {
    let M = 24, N = 5
    let a = year % 4
    let b = year % 7
    let c = year % 19
    let d = (19 * c + M) % 30
    let e = (2 * a + 4 * b + 6 * d + N) % 7
    let f = (c + 11 * d + 22 * e) / 451
    var day   = 22 + d + e - 7 * f
    var month = 3
    if day > 31 { day -= 31; month = 4 }
    var comps = DateComponents()
    comps.day = day; comps.month = month; comps.year = year
    return Calendar.current.date(from: comps)!
}

private func nextEaster() -> Date {
    let year   = Calendar.current.component(.year, from: Date())
    let easter = computeEaster(for: year)
    return easter >= Date() ? easter : computeEaster(for: year + 1)
}

// MARK: - Year Progress Ring

private struct YearRingView: View {
    let days: Int
    @Environment(\.colorScheme) private var colorScheme

    private var progress: Double { min(1.0, max(0, Double(days) / 365.0)) }

    private var ringPurple: Color {
        colorScheme == .dark ? Color(red: 0.80, green: 0.50, blue: 1.00)
                             : Color(red: 0.52, green: 0.15, blue: 0.85)
    }
    private var ringGold: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.78, blue: 0.20)
                             : Color(red: 0.68, green: 0.46, blue: 0.00)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 13)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ringPurple, ringGold, ringGold],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: progress)
                .shadow(color: ringGold.opacity(0.38), radius: 6)
        }
        .frame(width: 88, height: 88)
    }
}

// MARK: - Main View

struct CalendarCalculationView: View {

    @State private var selectedDate:        Date   = Date()
    @State private var showEventAlert:      Bool   = false
    @State private var eventTitle:          String = ""
    @State private var showCalendarError:   Bool   = false
    @State private var calendarErrorMsg:    String = ""
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Adaptive accent colors

    private var purpleAccent: Color {
        colorScheme == .dark ? Color(red: 0.80, green: 0.50, blue: 1.00)
                             : Color(red: 0.52, green: 0.15, blue: 0.85)
    }
    private var goldAccent: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.78, blue: 0.20)
                             : Color(red: 0.68, green: 0.46, blue: 0.00)
    }
    private var christmasAccent: Color {
        colorScheme == .dark ? Color(red: 1.00, green: 0.32, blue: 0.32)
                             : Color(red: 0.80, green: 0.08, blue: 0.08)
    }
    private var easterAccent: Color {
        colorScheme == .dark ? Color(red: 0.40, green: 0.92, blue: 0.55)
                             : Color(red: 0.05, green: 0.58, blue: 0.30)
    }
    private var glassTintPurple: Color {
        colorScheme == .dark ? Color(red: 0.14, green: 0.05, blue: 0.38)
                             : Color(red: 0.88, green: 0.78, blue: 1.00)
    }

    // MARK: Computed

    private var daysUntil: Int {
        CalendarCalculation().calculateDaysBetweenTwoDates(start: Date(), end: selectedDate)
    }

    private var daysUntilChristmas: Int {
        CalendarCalculation().calculateDaysBetweenTwoDates(start: Date(), end: nextChristmas())
    }

    private var daysUntilEaster: Int {
        CalendarCalculation().calculateDaysBetweenTwoDates(start: Date(), end: nextEaster())
    }

    private var countdownColor: Color {
        if daysUntil > 0 {
            return colorScheme == .dark ? Color(red: 1.00, green: 0.80, blue: 0.20)
                                        : Color(red: 0.68, green: 0.46, blue: 0.00)
        }
        if daysUntil < 0 {
            return colorScheme == .dark ? Color(red: 1.00, green: 0.38, blue: 0.38)
                                        : Color(red: 0.82, green: 0.12, blue: 0.12)
        }
        return colorScheme == .dark ? Color(red: 0.38, green: 0.95, blue: 0.60)
                                    : Color(red: 0.05, green: 0.60, blue: 0.32)
    }

    private var countdownLabel: LocalizedStringKey {
        if daysUntil == 0 { return "Today!" }
        if daysUntil > 0  { return "days until event" }
        return "days ago"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        daysCountdownCard
                        quickActionsRow
                        datePickerCard
                        addToCalendarButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("New Calendar Event", isPresented: $showEventAlert) {
            TextField("Event title", text: $eventTitle)
            Button("Add") { addCalendarEvent() }
            Button("Cancel", role: .cancel) { eventTitle = "" }
        } message: {
            let dateStr = selectedDate.formatted(date: .long, time: .omitted)
            Text("Add event on \(dateStr)")
        }
        .alert("Calendar Error", isPresented: $showCalendarError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarErrorMsg)
        }
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
                Color(red: 0.10, green: 0.04, blue: 0.28),
                Color(red: 0.16, green: 0.06, blue: 0.38),
                Color(red: 0.08, green: 0.04, blue: 0.26),
                Color(red: 0.12, green: 0.05, blue: 0.35),
                Color(red: 0.22, green: 0.08, blue: 0.50),
                Color(red: 0.10, green: 0.04, blue: 0.32),
                Color(red: 0.06, green: 0.02, blue: 0.20),
                Color(red: 0.12, green: 0.05, blue: 0.30),
                Color(red: 0.08, green: 0.03, blue: 0.22)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.75, green: 0.45, blue: 1.0).opacity(0.16))
                    .frame(width: 50, height: 50)
                Image(systemName: "calendar")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [purpleAccent, purpleAccent.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Calendar Calculator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Count days to any date, Christmas or Easter")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Days Countdown

    private var daysCountdownCard: some View {
        HStack(spacing: 18) {
            YearRingView(days: abs(daysUntil))

            VStack(alignment: .leading, spacing: 4) {
                Text(abs(daysUntil).formatted())
                    .font(.system(size: 48, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(countdownColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35), value: daysUntil)

                Text(countdownLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.65))

                Text(selectedDate.formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.35))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.tint(glassTintPurple),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .animation(.spring(response: 0.3), value: daysUntil)
    }

    // MARK: Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickCard(
                emoji: "🎄",
                label: "Christmas",
                date: nextChristmas(),
                days: daysUntilChristmas,
                accent: christmasAccent
            ) {
                withAnimation(.spring(response: 0.35)) { selectedDate = nextChristmas() }
            }

            quickCard(
                emoji: "🐣",
                label: "Easter",
                date: nextEaster(),
                days: daysUntilEaster,
                accent: easterAccent
            ) {
                withAnimation(.spring(response: 0.35)) { selectedDate = nextEaster() }
            }
        }
    }

    @ViewBuilder
    private func quickCard(
        emoji: String,
        label: LocalizedStringKey,
        date: Date,
        days: Int,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(emoji).font(.title3)
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                }
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.42))
                Spacer(minLength: 6)
                Text(days.formatted())
                    .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                Text("days")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(accent.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Date Picker

    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption.weight(.semibold))
                Text("Pick a date")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.primary.opacity(0.50))

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(purpleAccent)
                .labelsHidden()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Add to Calendar

    private var addToCalendarButton: some View {
        Button {
            eventTitle = ""
            showEventAlert = true
        } label: {
            Label(
                "Add to Calendar",
                systemImage: "calendar.badge.plus"
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
    }

    // MARK: Calendar Event Action

    private func addCalendarEvent() {
        let title = eventTitle.isEmpty
            ? "Event" : eventTitle
        let start = selectedDate
        let end   = CalendarCalculation().addTimeToDate(date: start, hours: 1)
        let desc  = "Generated by DailyToolbox App"
        Task {
            let cal = CalendarCalculation()
            do {
                try await cal.addEventToCalendar(
                    title: title,
                    description: desc,
                    startDate: start,
                    endDate: end
                )
            } catch {
                calendarErrorMsg = error.localizedDescription
                showCalendarError = true
            }
        }
        eventTitle = ""
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarCalculationView()
    }
}
