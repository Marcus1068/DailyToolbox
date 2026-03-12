//
//  ContentView.swift
//  DailyToolbox
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    // iPad/Mac: pre-select first tool so detail column is never empty
    @State private var selectedItem: ToolItem? = ToolSection.catalogue.first?.items.first
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
        case "showColorPicker":  ColorPickerView()
        case "showAreaVolume":   AreaVolumeView()
        case "showOhmsLaw":      OhmsLawView()
        case "showLoan":         LoanCalculatorView()
        case "showBMI":          BMIView()
        case "showFuelCost":     FuelCostView()
        case "showAspectRatio":  AspectRatioView()
        case "showRandomizer":   RandomizerView()
        case "showGermanHolidays": GermanHolidaysView()
        case "showHolidays":     GermanHolidaysView()
        case "showCalendar":     CalendarCalculationView()
        case "showHorizon":      HorizonView()
        case "showSunrise":      SunriseView()
        case "showWindChill":    WindChillView()
        case "showMoonPhase":    MoonPhaseView()
        case "showResistor":     ResistorColorCodeView()
        case "showBenchmark":    BenchmarkView()
        case "showAbout":        AboutView()
        default:                 ToolPlaceholder()
        }
    }
}

#Preview {
    ContentView()
}
