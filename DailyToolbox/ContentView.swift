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
        case "showBarcodeScanner": BarcodeScannerView()
        case "showColorPicker":  ColorPickerView()
        case "showAreaVolume":   AreaVolumeView()
        case "showOhmsLaw":      OhmsLawView()
        case "showLoan":         LoanCalculatorView()
        case "showBMI":          BMIView()
        case "showStatistics":   StatisticsView()
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
        case "showPeriodicTable": PeriodicTableView()
        case "showBenchmark":    BenchmarkView()
        case "showAbout":        AboutView()
        default:                 ToolPlaceholder()
        }
    }
}

#Preview {
    ContentView()
}
