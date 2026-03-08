/*
 MasterView.swift
 DailyToolbox

 SwiftUI home screen shown as the primary panel in NavigationSplitView.
 Each ToolCard uses NavigationLink(value:) so that:
   • on iPad (regular width)  → selection appears in the detail column
   • on iPhone (compact width) → the destination is pushed onto the stack
 The navigationDestination(for: ToolItem.self) lives in ContentView's detail
 NavigationStack, which is where Apple recommends placing it for split views.
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
            ToolItem(id: "showPercentage",   name: "Percentage",     subtitle: "Base & rate",                   icon: "percent",                        color: Color(red: 0.00, green: 0.80, blue: 0.85), segueId: "showPercentage"),
            ToolItem(id: "showCurrency",     name: "Currency",       subtitle: "Exchange rates",                icon: "coloncurrencysign.circle.fill",  color: Color(red: 0.45, green: 0.20, blue: 0.90), segueId: "showCurrency"),
            ToolItem(id: "showDecimal",      name: "Number Bases",   subtitle: "Hex \u{00B7} Dec \u{00B7} Bin", icon: "number.circle.fill",             color: Color(red: 0.20, green: 0.45, blue: 1.00), segueId: "showDecimal"),
            ToolItem(id: "showInterestRate", name: "Interest Rate",  subtitle: "Compound & simple",             icon: "chart.line.uptrend.xyaxis",      color: Color(red: 0.00, green: 0.78, blue: 0.42), segueId: "showInterestRate"),
            ToolItem(id: "showRoman",        name: "Roman Numerals", subtitle: "Bi-directional",                icon: "character.book.closed.fill",     color: Color(red: 0.78, green: 0.10, blue: 0.18), segueId: "showRoman"),
        ]),
        ToolSection(title: "Conversions", items: [
            ToolItem(id: "showTemp",         name: "Temperature",    subtitle: "\u{00B0}C \u{00B7} \u{00B0}F \u{00B7} K", icon: "thermometer.medium",  color: Color(red: 0.95, green: 0.42, blue: 0.08), segueId: "showTemp"),
            ToolItem(id: "showPower",        name: "Power",          subtitle: "Watts & cost",                  icon: "bolt.fill",                      color: Color(red: 1.00, green: 0.60, blue: 0.00), segueId: "showPower"),
            ToolItem(id: "showTranslation",  name: "Translation",    subtitle: "dict.leo.org",                  icon: "character.bubble.fill",          color: Color(red: 0.00, green: 0.65, blue: 0.72), segueId: "showTranslation"),
        ]),
        ToolSection(title: "Tools", items: [
            ToolItem(id: "showCalendar",     name: "Calendar",       subtitle: "Date calculations",             icon: "calendar.circle.fill",           color: Color(red: 0.55, green: 0.10, blue: 0.82), segueId: "showCalendar"),
            ToolItem(id: "showHorizon",      name: "Horizon",        subtitle: "Visibility range",              icon: "binoculars.fill",                color: Color(red: 0.10, green: 0.58, blue: 0.90), segueId: "showHorizon"),
            ToolItem(id: "showBenchmark",    name: "Benchmark",      subtitle: "Device speed",                  icon: "speedometer",                    color: Color(red: 0.00, green: 0.82, blue: 1.00), segueId: "showBenchmark"),
            ToolItem(id: "showAbout",        name: "About",          subtitle: "DailyToolbox",                  icon: "info.circle.fill",               color: Color(red: 0.20, green: 0.50, blue: 1.00), segueId: "showAbout"),
        ]),
    ]
}

// MARK: - MasterView

struct MasterView: View {

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)]

    var body: some View {
        ZStack {
            // Midnight aurora background
            MeshGradient(width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.16),
                    Color(red: 0.06, green: 0.02, blue: 0.22),
                    Color(red: 0.03, green: 0.05, blue: 0.18),
                    Color(red: 0.05, green: 0.03, blue: 0.20),
                    Color(red: 0.09, green: 0.03, blue: 0.28),
                    Color(red: 0.04, green: 0.06, blue: 0.22),
                    Color(red: 0.03, green: 0.06, blue: 0.14),
                    Color(red: 0.05, green: 0.10, blue: 0.20),
                    Color(red: 0.02, green: 0.05, blue: 0.16)
                ]
            )
            .ignoresSafeArea()

            GlassEffectContainer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(ToolSection.catalogue) { section in
                            sectionBlock(section)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    // MARK: - Section block

    private func sectionBlock(_ section: ToolSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(section.items) { item in
                    ToolCard(item: item)
                }
            }
        }
    }
}

// MARK: - Tool Card

private struct ToolCard: View {

    let item: ToolItem
    @State private var pressed = false

    var body: some View {
        NavigationLink(value: item) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.18))
                        .frame(width: 60, height: 60)
                    Image(systemName: item.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(item.color)
                }

                VStack(spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.50))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
            .glassEffect(
                .regular.tint(item.color.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.94 : 1.0)
        .animation(.spring(duration: 0.18, bounce: 0.3), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true  }
                .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        MasterView()
            .navigationTitle("DailyToolbox")
    } detail: {
        NavigationStack {
            ToolPlaceholder()
                .navigationDestination(for: ToolItem.self) { _ in
                    ToolPlaceholder()
                }
        }
    }
}
