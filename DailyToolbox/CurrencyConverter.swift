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
//  CurrencyConverter.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//


// uses this XML from ECB website:
/* <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
<gesmes:subject>Reference rates</gesmes:subject>
<gesmes:Sender>
<gesmes:name>European Central Bank</gesmes:name>
</gesmes:Sender>
<Cube>
<Cube time="2020-03-06">
<Cube currency="USD" rate="1.1336"/>
...
</Cube>
</Cube>
</gesmes:Envelope>
 */


import Foundation

// store struct in JSON as file in case of network problems
struct Cube: Codable {
    var currency: String
    var rate: String
}

private let fileName: String = "currencyData.json"
private let xmlFile: String = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

// works based on EUR reference currency
class CurrencyConverter: NSObject, XMLParserDelegate {
    
    // variables
    private var elementName: String = String()
    private var currency = String()
    private var rate = String()
    private var lastUpdate = String()
    private var cubes: [Cube] = []

    private override init() {
        super.init()
    }
    
    /// Async factory: fetches live rates from ECB, falls back to cached JSON on failure.
    static func load() async -> CurrencyConverter {
        let converter = CurrencyConverter()
        await converter.fetchRates()
        return converter
    }

    private func fetchRates() async {
        // add EUR to list since we only get values from EUR to xxx and EUR is not included
        cubes = [Cube(currency: "EUR", rate: "1.0")]

        guard let xmlFileURL = URL(string: xmlFile) else {
            await loadCachedRates()
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: xmlFileURL)
            let parser = XMLParser(data: data)
            parser.delegate = self
            if parser.parse() {
                lastUpdate = Date().toMediumDateString()
                await saveRatesToCache()
            } else {
                await loadCachedRates()
            }
        } catch {
            await loadCachedRates()
        }
    }

    private func saveRatesToCache() async {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(cubes),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { return }
        let filePath = URL.documentsDirectory.appending(path: fileName)
        do {
            try jsonStr.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Writing JSON file failed: \(error)")
        }
    }

    private func loadCachedRates() async {
        let pathURL = URL.documentsDirectory.appending(path: fileName)
        do {
            let contents = try String(contentsOf: pathURL, encoding: .utf8)
            let decoder = JSONDecoder()
            guard let jsonData = contents.data(using: .utf8),
                  let cubeCopy = try? decoder.decode([Cube].self, from: jsonData) else { return }
            cubes = cubeCopy
            lastUpdate = "offline usage, no network"
        } catch {
            print("File Read Error: \(error)")
        }
    }
    
    // MARK: - Public API

    func getLastUpdate() -> String {
        return lastUpdate
    }
    
    func getCurrencyList() -> [Cube] {
        return cubes
    }
    
    func getCurrencyStrings() -> [String] {
        return cubes.map(\.currency).removingDuplicates()
    }
    
    func getCurrencyArray() -> [[String]] {
        return cubes.map { [$0.currency, $0.currency] }.removingDuplicates()
    }
    
    func getRate(currency: String) -> Double {
        return cubes.first(where: { $0.currency == currency }).flatMap { Double($0.rate) } ?? 1.0
    }
    
    // convert from currency A to currency B
    // 1. convert base currency to EUR
    // 2. compute EUR * dest
    func convertFromTo(baseCurrency: String, destCurrency: String) -> Double {
        let base = getRate(currency: baseCurrency)
        let dest = getRate(currency: destCurrency)
        return 1.0 / base * dest
    }
    
    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "Cube" {
            if let name = attributeDict["currency"] {
                currency = name
            }
            if let tag = attributeDict["rate"] {
                rate = tag
            }
        }
        self.elementName = elementName
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Cube", !currency.isEmpty, !rate.isEmpty {
            cubes.append(Cube(currency: currency, rate: rate))
            currency = ""
            rate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {}
        
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parser failure error: ", parseError)
    }
}

// MARK: - Preview Support

#if DEBUG
extension CurrencyConverter {
    /// Returns a pre-populated instance for SwiftUI Previews (no network call needed).
    static var preview: CurrencyConverter {
        let c = CurrencyConverter()
        c.cubes = [
            Cube(currency: "EUR", rate: "1.0"),
            Cube(currency: "USD", rate: "1.0847"),
            Cube(currency: "GBP", rate: "0.8563"),
            Cube(currency: "JPY", rate: "161.48"),
            Cube(currency: "CHF", rate: "0.9712"),
            Cube(currency: "AUD", rate: "1.6632"),
            Cube(currency: "CAD", rate: "1.4891"),
            Cube(currency: "CNY", rate: "7.8721"),
            Cube(currency: "SEK", rate: "11.2340"),
            Cube(currency: "NOK", rate: "11.7650"),
            Cube(currency: "DKK", rate: "7.4600"),
            Cube(currency: "PLN", rate: "4.2480"),
        ]
        c.lastUpdate = "Preview data"
        return c
    }
}
#endif
