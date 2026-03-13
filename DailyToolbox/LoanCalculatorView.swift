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
//  LoanCalculatorView.swift
//  DailyToolbox
//

import SwiftUI

private enum TermUnit: String, CaseIterable {
    case years  = "Years"
    case months = "Months"
    var localizedKey: LocalizedStringKey {
        switch self {
        case .years:  return "Years"
        case .months: return "Months"
        }
    }
}

private struct LoanResult {
    let monthlyPayment: Double
    let totalPaid:      Double
    let totalInterest:  Double
    let numPayments:    Int

    static func calculate(principal: Double, annualRate: Double, termMonths: Int) -> LoanResult? {
        guard principal > 0, annualRate >= 0, termMonths > 0 else { return nil }
        let n = Double(termMonths)
        let monthly: Double
        if annualRate == 0 {
            monthly = principal / n
        } else {
            let r = annualRate / 100.0 / 12.0
            monthly = principal * r * pow(1 + r, n) / (pow(1 + r, n) - 1)
        }
        let total    = monthly * n
        let interest = total - principal
        return LoanResult(monthlyPayment: monthly, totalPaid: total,
                          totalInterest: interest, numPayments: termMonths)
    }
}

struct LoanCalculatorView: View {
    @State private var principalText = ""
    @State private var rateText      = ""
    @State private var termText      = ""
    @State private var termUnit: TermUnit = .years
    @State private var result: LoanResult? = nil
    @FocusState private var focused: Int?
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color       { colorScheme == .dark ? Color(red: 0.45, green: 0.70, blue: 1.00) : Color(red: 0.08, green: 0.40, blue: 0.88) }
    private var totalPaidColor: Color   { colorScheme == .dark ? Color(red: 0.70, green: 0.90, blue: 1.00) : Color(red: 0.06, green: 0.42, blue: 0.82) }
    private var totalInterestColor: Color { colorScheme == .dark ? Color(red: 1.00, green: 0.65, blue: 0.45) : Color(red: 0.80, green: 0.32, blue: 0.00) }
    private var principalBarColor: Color  { colorScheme == .dark ? Color(red: 0.35, green: 0.65, blue: 1.00) : Color(red: 0.10, green: 0.40, blue: 0.88) }
    private var interestBarColor: Color   { colorScheme == .dark ? Color(red: 1.00, green: 0.55, blue: 0.35) : Color(red: 0.82, green: 0.28, blue: 0.05) }
    private var headerCircle: LinearGradient { LinearGradient(colors: [colorScheme == .dark ? Color(red:0.35,green:0.60,blue:1.00) : Color(red:0.10,green:0.38,blue:0.88), colorScheme == .dark ? Color(red:0.20,green:0.40,blue:0.90) : Color(red:0.06,green:0.22,blue:0.78)], startPoint: .topLeading, endPoint: .bottomTrailing) }

    private func calculate() {
        let p = Double(principalText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let r = Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let t = Double(termText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard p > 0, t > 0 else { result = nil; return }
        let months = termUnit == .years ? Int(t * 12) : Int(t)
        result = LoanResult.calculate(principal: p, annualRate: r, termMonths: months)
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            principalText = ""; rateText = ""; termText = ""; result = nil
        }
        focused = nil
    }

    private func currency(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.maximumFractionDigits = 2; f.minimumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 14) {
                    GlassEffectContainer { headerCard }
                    GlassEffectContainer { inputCard }
                    if let result { GlassEffectContainer { resultCard(result) } }
                }
                .padding(.horizontal, 20).padding(.vertical, 24)
            }
            .onTapGesture { focused = nil }

            .accessibilityAddTraits(.isButton)

            .accessibilityLabel("Dismiss keyboard")
        }
        .navigationTitle("Loan Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [[0.0,0.0],[0.5,0.0],[1.0,0.0],[0.0,0.5],[0.5,0.5],[1.0,0.5],[0.0,1.0],[0.5,1.0],[1.0,1.0]],
            colors: [
                Color(red:0.04,green:0.07,blue:0.20), Color(red:0.05,green:0.09,blue:0.25), Color(red:0.04,green:0.07,blue:0.22),
                Color(red:0.05,green:0.09,blue:0.24), Color(red:0.07,green:0.12,blue:0.32), Color(red:0.05,green:0.09,blue:0.26),
                Color(red:0.03,green:0.06,blue:0.18), Color(red:0.05,green:0.08,blue:0.22), Color(red:0.03,green:0.06,blue:0.18)
            ]
        ).ignoresSafeArea()
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(headerCircle)
                Image(systemName: "house.fill").font(.title2).foregroundStyle(Color.primary)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("Loan Calculator").font(.headline.weight(.bold)).foregroundStyle(Color.primary)
                Text("Monthly payment & total cost").font(.caption).foregroundStyle(Color.primary.opacity(0.65))
            }
            Spacer()
            Button(action: clearAll) {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.primary.opacity(0.75))
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Loan Details").font(.subheadline.weight(.bold)).foregroundStyle(accent)
            loanField(label: "Loan Amount", placeholder: "100000", text: $principalText, focusTag: 1, prefix: "💰")
            loanField(label: "Annual Interest Rate (%)", placeholder: "3.5", text: $rateText, focusTag: 2, prefix: "📈")
            VStack(alignment: .leading, spacing: 6) {
                Text("Loan Term").font(.caption.weight(.semibold)).foregroundStyle(accent.opacity(0.80))
                HStack(spacing: 10) {
                    TextField("30", text: $termText)
                        .keyboardType(.decimalPad).focused($focused, equals: 3)
                        .font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(Color.primary).tint(accent)
                        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.07)))
                        .onChange(of: termText) { _, _ in guard focused == 3 else { return }; calculate() }
                    HStack(spacing: 0) {
                        ForEach(TermUnit.allCases, id: \.self) { unit in
                            let sel = termUnit == unit
                            Button {
                                withAnimation(.spring(response: 0.25)) { termUnit = unit; calculate() }
                            } label: {
                                Text(unit.localizedKey)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(sel ? .black : Color.primary.opacity(0.65))
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(sel ? accent : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
                }
            }
            Button(action: calculate) {
                Text("Calculate").font(.headline.weight(.bold)).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(accent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func loanField(label: LocalizedStringKey, placeholder: LocalizedStringKey, text: Binding<String>, focusTag: Int, prefix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(accent.opacity(0.80))
            HStack(spacing: 10) {
                Text(prefix).font(.title3)
                TextField(placeholder, text: text).keyboardType(.decimalPad).focused($focused, equals: focusTag)
                    .font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(Color.primary).tint(accent)
                    .onChange(of: text.wrappedValue) { _, _ in guard focused == focusTag else { return }; calculate() }
            }
            .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.07)))
        }
    }

    @ViewBuilder
    private func resultCard(_ res: LoanResult) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Monthly Payment").font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.60))
                Text(currency(res.monthlyPayment))
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent).minimumScaleFactor(0.6).lineLimit(1)
                Text("× \(res.numPayments) payments").font(.caption).foregroundStyle(Color.primary.opacity(0.45))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            Divider().overlay(Color.primary.opacity(0.10))
            HStack(spacing: 0) {
                summaryCell(label: "Total Paid", value: currency(res.totalPaid), color: totalPaidColor)
                Divider().frame(height: 50).overlay(Color.primary.opacity(0.10))
                summaryCell(label: "Total Interest", value: currency(res.totalInterest), color: totalInterestColor)
            }
            .padding(.vertical, 14)
            Divider().overlay(Color.primary.opacity(0.10))
            VStack(spacing: 8) {
                HStack {
                    Text("Principal").font(.caption2.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
                    Spacer()
                    Text("Interest").font(.caption2.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
                }
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        let ratio = CGFloat(res.totalPaid > 0 ? (res.totalPaid - res.totalInterest) / res.totalPaid : 1.0)
                        RoundedRectangle(cornerRadius: 6).fill(principalBarColor)
                            .frame(width: max(4, geo.size.width * ratio - 2))
                        RoundedRectangle(cornerRadius: 6).fill(interestBarColor)
                    }
                    .frame(height: 12)
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func summaryCell(label: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.55))
            Text(value).font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(color).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack { LoanCalculatorView() }
}
