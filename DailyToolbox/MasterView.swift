/*
 MasterView.swift
 DailyToolbox

 SwiftUI home screen — primary panel in NavigationSplitView (iPad) and root
 of NavigationStack (iPhone). Each ToolCard is a NavigationLink(value: item)
 so SwiftUI routes to the registered navigationDestination automatically in
 both regular (split) and compact (stack) environments.
*/

import SwiftUI
import UIKit

// MARK: - Color helpers

private extension Color {
    /// Returns a darkened, more-saturated version for use in light mode,
    /// where the original bright pastel would be hard to see on white glass.
    func deepened() -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h,
                     saturation: min(s * 1.15, 1.0),
                     brightness: b * 0.60,
                     opacity: a)
    }
}

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
            ToolItem(id: "showLoan",         name: "Loan Calculator",subtitle: "Monthly payment & interest",     icon: "house.fill",                     color: Color(red: 0.35, green: 0.55, blue: 0.95), segueId: "showLoan"),
            ToolItem(id: "showBMI",          name: "BMI Calculator", subtitle: "BMI · BMR · Ideal weight",       icon: "figure.stand",                   color: Color(red: 0.90, green: 0.35, blue: 0.30), segueId: "showBMI"),
        ]),
        ToolSection(title: "Conversions", items: [
            ToolItem(id: "showTemp",         name: "Temperature",    subtitle: "\u{00B0}C \u{00B7} \u{00B0}F \u{00B7} K", icon: "thermometer.medium",  color: Color(red: 0.95, green: 0.42, blue: 0.08), segueId: "showTemp"),
            ToolItem(id: "showUnitConv",     name: "Unit Converter", subtitle: "Length · Weight · Volume · Speed",          icon: "arrow.left.arrow.right", color: Color(red: 0.20, green: 0.55, blue: 1.00), segueId: "showUnitConv"),
            ToolItem(id: "showPower",        name: "Power",          subtitle: "Watts & cost",                   icon: "bolt.fill",                      color: Color(red: 1.00, green: 0.60, blue: 0.00), segueId: "showPower"),
            ToolItem(id: "showTranslation",  name: "Translation",    subtitle: "dict.leo.org",                   icon: "character.bubble.fill",          color: Color(red: 0.00, green: 0.65, blue: 0.72), segueId: "showTranslation"),
            ToolItem(id: "showColorPicker",  name: "Color Picker",   subtitle: "HEX · RGB · HSB · CMYK",        icon: "paintpalette.fill",              color: Color(red: 0.80, green: 0.30, blue: 0.90), segueId: "showColorPicker"),
            ToolItem(id: "showAreaVolume",   name: "Area & Volume",  subtitle: "Shapes & formulas",              icon: "square.on.circle",               color: Color(red: 0.25, green: 0.75, blue: 0.40), segueId: "showAreaVolume"),
            ToolItem(id: "showAspectRatio",  name: "Aspect Ratio",   subtitle: "Scale & ratio calculator",       icon: "aspectratio.fill",               color: Color(red: 0.70, green: 0.40, blue: 1.00), segueId: "showAspectRatio"),
        ]),
        ToolSection(title: "Tools", items: [
            ToolItem(id: "showHolidays",      name: "German Holidays",subtitle: "Public & school holidays",       icon: "flag.fill",                      color: Color(red: 0.95, green: 0.75, blue: 0.20), segueId: "showHolidays"),
            ToolItem(id: "showFuelCost",      name: "Fuel Cost",      subtitle: "Trip · Consumption · Price",     icon: "fuelpump.fill",                  color: Color(red: 0.25, green: 0.78, blue: 0.55), segueId: "showFuelCost"),
            ToolItem(id: "showRandomizer",    name: "Randomizer",     subtitle: "Coin · Dice · Number · List",    icon: "dice.fill",                      color: Color(red: 1.00, green: 0.60, blue: 0.15), segueId: "showRandomizer"),
            ToolItem(id: "showTipSplitter",  name: "Tip Splitter",   subtitle: "Bill & tip per person",          icon: "fork.knife.circle.fill",         color: Color(red: 0.90, green: 0.62, blue: 0.10), segueId: "showTipSplitter"),
            ToolItem(id: "showQRCode",       name: "QR Code",        subtitle: "URL · Text · WiFi · Contact",    icon: "qrcode",                         color: Color(red: 0.55, green: 0.35, blue: 0.95), segueId: "showQRCode"),
            ToolItem(id: "showOhmsLaw",      name: "Ohm's Law",      subtitle: "V · I · R · P calculator",      icon: "bolt.horizontal.circle.fill",    color: Color(red: 1.00, green: 0.70, blue: 0.15), segueId: "showOhmsLaw"),
            ToolItem(id: "showCalendar",     name: "Calendar",       subtitle: "Date calculations",              icon: "calendar.circle.fill",           color: Color(red: 0.55, green: 0.10, blue: 0.82), segueId: "showCalendar"),
            ToolItem(id: "showGermanHolidays",name: "German Holidays",subtitle: "Public & school holidays",       icon: "flag.fill",                      color: Color(red: 0.85, green: 0.15, blue: 0.15), segueId: "showGermanHolidays"),
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
    @State private var showAbout = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Adaptive mesh gradient colors

    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.10, blue: 0.28), Color(red: 0.10, green: 0.12, blue: 0.38), Color(red: 0.07, green: 0.09, blue: 0.30),
                Color(red: 0.12, green: 0.10, blue: 0.40), Color(red: 0.16, green: 0.12, blue: 0.52), Color(red: 0.10, green: 0.11, blue: 0.38),
                Color(red: 0.07, green: 0.10, blue: 0.26), Color(red: 0.11, green: 0.13, blue: 0.36), Color(red: 0.08, green: 0.09, blue: 0.28)
            ]
        } else {
            return [
                Color(red: 0.92, green: 0.93, blue: 0.97), Color(red: 0.88, green: 0.90, blue: 0.96), Color(red: 0.90, green: 0.92, blue: 0.97),
                Color(red: 0.86, green: 0.88, blue: 0.95), Color(red: 0.83, green: 0.86, blue: 0.94), Color(red: 0.87, green: 0.89, blue: 0.96),
                Color(red: 0.90, green: 0.92, blue: 0.97), Color(red: 0.88, green: 0.90, blue: 0.95), Color(red: 0.91, green: 0.93, blue: 0.97)
            ]
        }
    }

    private var titleGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(colors: [Color.primary, Color(red: 0.30, green: 0.50, blue: 0.90)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.10, green: 0.30, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var titleShadowColor: Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5)
                             : Color(red: 0.1, green: 0.2, blue: 0.6).opacity(0.25)
    }

    var body: some View {
        ZStack {
            // Deep blue-slate background — noticeably lighter than the cards
            MeshGradient(width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: meshColors
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.85))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showAbout = false }
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }

    private var appHeader: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("DailyToolbox")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(titleGradient)
                    .shadow(color: titleShadowColor, radius: 12)

                Text("v\(version)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.40))
            }

            Text("24 built-in tools")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.55))
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
                    .foregroundStyle(Color.primary.opacity(0.70))
                    .textCase(.uppercase)

                Rectangle()
                    .fill(Color.primary.opacity(0.12))
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
    @Environment(\.colorScheme) private var colorScheme

    private var displayColor: Color {
        colorScheme == .dark ? item.color : item.color.deepened()
    }

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
                    .fill(displayColor.opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: item.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(displayColor)
                    .shadow(color: displayColor.opacity(0.5), radius: 6)
            }

            VStack(spacing: 2) {
                Text(LocalizedStringKey(item.name))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(LocalizedStringKey(item.subtitle))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .glassEffect(
            .regular.tint(displayColor.opacity(0.14)),
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
