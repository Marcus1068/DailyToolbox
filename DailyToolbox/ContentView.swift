//
//  ContentView.swift
//  DailyToolbox
//

import SwiftUI

struct ContentView: View {
    @State private var selectedItem: ToolItem?

    var body: some View {
        NavigationSplitView {
            MasterView(selectedItem: $selectedItem)
                .navigationTitle("DailyToolbox")
        } detail: {
            NavigationStack {
                detailView(for: selectedItem)
            }
        }
        .task { appstoreReview() }
    }

    @ViewBuilder
    private func detailView(for item: ToolItem?) -> some View {
        switch item?.segueId {
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
        default:
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
}

#Preview {
    ContentView()
}
