/*
 MasterView.swift
 DailyToolbox

 SwiftUI home screen — primary panel in NavigationSplitView (iPad) and root
 of NavigationStack (iPhone). Each ToolCard is a NavigationLink(value: item)
 so SwiftUI routes to the registered navigationDestination automatically in
 both regular (split) and compact (stack) environments.
*/

import SwiftUI

// MARK: - Data model

struct ToolItem: Identifiable, Hashable {
    let id: String          // stable id = segueId
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let segueId: String

    static func == (lhs: ToolItem, rhs: ToolItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ToolSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [ToolItem]
}

// MARK: - Static catalogue

extension ToolSection {
    static let catalogue: [ToolSection] = [
        ToolSection(title: "Numbers", items: [
            ToolItem(id: "showPercentage",   name: "Percentage",     subtitle: "Base & rate",                    icon: "percent",                        color: Color(red: 0.00, green: 0.80, blue: 0.85), segueId: "showPercentage"),
            ToolItem(id: "showCurrency",     name: "Currency",       subtitle: "Exchange rates",                 icon: "coloncurrencysign.circle.fill",  color: Color(red: 0.45, green: 0.20, blue: 0.90), segueId: "showCurrency"),
            ToolItem(id: "showDecimal",      name: "Number Bases",   subtitle: "Hex \u{00B7} Dec \u{00B7} Bin",  icon: "number.circle.fill",             color: Color(red: 0.20, green: 0.45, blue: 1.00), segueId: "showDecimal"),
            ToolItem(id: "showInterestRate", name: "Interest Rate",  subtitle: "Compound & simple",              icon: "chart.line.uptrend.xyaxis",      color: Color(red: 0.00, green: 0.78, blue: 0.42), segueId: "showInterestRate"),
            ToolItem(id: "showRoman",        name: "Roman Numerals", subtitle: "Bi-directional",                 icon: "character.book.closed.fill",     color: Color(red: 0.78, green: 0.10, blue: 0.18), segueId: "showRoman"),
        ]),
        ToolSection(title: "Conversions", items: [
            ToolItem(id: "showTemp",         name: "Temperature",    subtitle: "\u{00B0}C \u{00B7} \u{00B0}F \u{00B7} K", icon: "thermometer.medium",  color: Color(red: 0.95, green: 0.42, blue: 0.08), segueId: "showTemp"),
            ToolItem(id: "showUnitConv",     name: "Unit Converter", subtitle: "Length · Weight · Volume · Speed",          icon: "arrow.left.arrow.right", color: Color(red: 0.20, green: 0.55, blue: 1.00), segueId: "showUnitConv"),
            ToolItem(id: "showPower",        name: "Power",          subtitle: "Watts & cost",                   icon: "bolt.fill",                      color: Color(red: 1.00, green: 0.60, blue: 0.00), segueId: "showPower"),
            ToolItem(id: "showTranslation",  name: "Translation",    subtitle: "dict.leo.org",                   icon: "character.bubble.fill",          color: Color(red: 0.00, green: 0.65, blue: 0.72), segueId: "showTranslation"),
        ]),
        ToolSection(title: "Tools", items: [
            ToolItem(id: "showTipSplitter",  name: "Tip Splitter",   subtitle: "Bill & tip per person",          icon: "fork.knife.circle.fill",         color: Color(red: 0.90, green: 0.62, blue: 0.10), segueId: "showTipSplitter"),
            ToolItem(id: "showCalendar",     name: "Calendar",       subtitle: "Date calculations",              icon: "calendar.circle.fill",           color: Color(red: 0.55, green: 0.10, blue: 0.82), segueId: "showCalendar"),
            ToolItem(id: "showHorizon",      name: "Horizon",        subtitle: "Visibility range",               icon: "binoculars.fill",                color: Color(red: 0.10, green: 0.58, blue: 0.90), segueId: "showHorizon"),
            ToolItem(id: "showBenchmark",    name: "Benchmark",      subtitle: "Device speed",                   icon: "speedometer",                    color: Color(red: 0.00, green: 0.82, blue: 1.00), segueId: "showBenchmark"),
            ToolItem(id: "showAbout",        name: "About",          subtitle: "DailyToolbox",                   icon: "info.circle.fill",               color: Color(red: 0.20, green: 0.50, blue: 1.00), segueId: "showAbout"),
        ]),
    ]
}

// MARK: - ToolPlaceholder (shared between ContentView and preview)

struct ToolPlaceholder: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(.secondary)
                Text("Select a tool")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - MasterView

struct MasterView: View {

    let onSelect: (ToolItem) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)]

    var body: some View {
        ZStack {
            // Deep blue-slate background — noticeably lighter than the cards
            MeshGradient(width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.28),
                    Color(red: 0.10, green: 0.12, blue: 0.38),
                    Color(red: 0.07, green: 0.09, blue: 0.30),
                    Color(red: 0.12, green: 0.10, blue: 0.40),
                    Color(red: 0.16, green: 0.12, blue: 0.52),
                    Color(red: 0.10, green: 0.11, blue: 0.38),
                    Color(red: 0.07, green: 0.10, blue: 0.26),
                    Color(red: 0.11, green: 0.13, blue: 0.36),
                    Color(red: 0.08, green: 0.09, blue: 0.28)
                ]
            )
            .ignoresSafeArea()

            GlassEffectContainer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Custom app header
                        appHeader

                        ForEach(ToolSection.catalogue) { section in
                            sectionBlock(section)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Color.clear }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var appHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DailyToolbox")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.75, green: 0.85, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5), radius: 12)

            Text("14 built-in tools")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    private func sectionBlock(_ section: ToolSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey(section.title))
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.70))
                    .textCase(.uppercase)

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(section.items) { item in
                    ToolCard(item: item, onSelect: onSelect)
                }
            }
        }
    }
}

// MARK: - Tool Card

private struct ToolCard: View {

    let item: ToolItem
    let onSelect: (ToolItem) -> Void

    var body: some View {
        Button { onSelect(item) } label: {
            cardContent
        }
        .buttonStyle(PressableCardStyle())
    }

    private var cardContent: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: item.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(item.color)
                    .shadow(color: item.color.opacity(0.5), radius: 6)
            }

            VStack(spacing: 2) {
                Text(LocalizedStringKey(item.name))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(LocalizedStringKey(item.subtitle))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .glassEffect(
            .regular.tint(item.color.opacity(0.14)),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
}

// A ButtonStyle that gives the spring-scale press feel without fighting
// NavigationLink's own gesture recogniser.
private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(duration: 0.18, bounce: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MasterView(onSelect: { _ in })
            .navigationDestination(for: ToolItem.self) { _ in ToolPlaceholder() }
    }
}
