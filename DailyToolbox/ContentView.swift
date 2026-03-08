//
//  ContentView.swift
//  DailyToolbox
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // iPhone: plain NavigationStack — navigationDestination is in the
            // same navigation context as the NavigationLink, so it always works.
            NavigationStack {
                MasterView()
                    .navigationTitle("DailyToolbox")
                    .navigationDestination(for: ToolItem.self) { item in
                        toolDetailView(for: item)
                    }
            }
        } else {
            // iPad / Mac Catalyst: split view — navigationDestination lives in the
            // detail NavigationStack, which is the correct side for split views.
            NavigationSplitView {
                MasterView()
                    .navigationTitle("DailyToolbox")
            } detail: {
                NavigationStack {
                    ToolPlaceholder()
                        .navigationDestination(for: ToolItem.self) { item in
                            toolDetailView(for: item)
                        }
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
