//
//  ContentView.swift
//  DailyToolbox
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    // iPad: direct selection drives the detail column
    @State private var selectedItem: ToolItem?
    // iPhone: explicit path so Button taps push onto the stack
    @State private var navPath = NavigationPath()

    var body: some View {
        if sizeClass == .compact {
            // ── iPhone ───────────────────────────────────────────────
            // Button in ToolCard appends to navPath; NavigationStack
            // resolves the destination in the same navigation context.
            NavigationStack(path: $navPath) {
                MasterView { item in navPath.append(item) }
                    .navigationDestination(for: ToolItem.self) { item in
                        toolDetailView(for: item)
                    }
            }
        } else {
            // ── iPad / Mac Catalyst ──────────────────────────────────
            // Button in ToolCard sets selectedItem; detail column
            // re-renders immediately — no cross-column link magic needed.
            NavigationSplitView {
                MasterView { item in selectedItem = item }
            } detail: {
                if let item = selectedItem {
                    toolDetailView(for: item)
                } else {
                    ToolPlaceholder()
                }
            }
        }
    }

    @ViewBuilder
    private func toolDetailView(for item: ToolItem) -> some View {
        switch item.segueId {
        case "showPercentage":   PercentageView()
        case "showCurrency":     CurrencyConverterView()
        case "showDecimal":      ConvertNumbersView()
        case "showInterestRate": InterestRateView()
        case "showRoman":        DecimalRomanNumbersView()
        case "showTemp":         TemperatureView()
        case "showPower":        PowerConsumptionView()
        case "showTranslation":  TranslationView()
        case "showUnitConv":     UnitConverterView()
        case "showTipSplitter":  TipSplitterView()
        case "showQRCode":       QRCodeView()
        case "showCalendar":     CalendarCalculationView()
        case "showHorizon":      HorizonView()
        case "showBenchmark":    BenchmarkView()
        case "showAbout":        AboutView()
        default:                 ToolPlaceholder()
        }
    }
}

#Preview {
    ContentView()
}
