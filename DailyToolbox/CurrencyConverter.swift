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
<Cube currency="JPY" rate="119.08"/>
<Cube currency="BGN" rate="1.9558"/>
<Cube currency="CZK" rate="25.458"/>
<Cube currency="DKK" rate="7.4697"/>
<Cube currency="GBP" rate="0.87165"/>
<Cube currency="HUF" rate="335.48"/>
<Cube currency="PLN" rate="4.3042"/>
<Cube currency="RON" rate="4.8110"/>
<Cube currency="SEK" rate="10.6145"/>
<Cube currency="CHF" rate="1.0589"/>
<Cube currency="ISK" rate="143.00"/>
<Cube currency="NOK" rate="10.4983"/>
<Cube currency="HRK" rate="7.5035"/>
<Cube currency="RUB" rate="77.5058"/>
<Cube currency="TRY" rate="6.9209"/>
<Cube currency="AUD" rate="1.7103"/>
<Cube currency="BRL" rate="5.2748"/>
<Cube currency="CAD" rate="1.5213"/>
<Cube currency="CNY" rate="7.8511"/>
<Cube currency="HKD" rate="8.8089"/>
<Cube currency="IDR" rate="16558.49"/>
<Cube currency="ILS" rate="3.9576"/>
<Cube currency="INR" rate="83.5860"/>
<Cube currency="KRW" rate="1351.63"/>
<Cube currency="MXN" rate="22.9958"/>
<Cube currency="MYR" rate="4.7294"/>
<Cube currency="NZD" rate="1.7858"/>
<Cube currency="PHP" rate="57.542"/>
<Cube currency="SGD" rate="1.5630"/>
<Cube currency="THB" rate="35.640"/>
<Cube currency="ZAR" rate="17.8514"/>
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


// need to be declared outside of class otherwise loses values after xml parser runs
private var cubes: [Cube] = []

private let fileName: String = "currencyData.json"
private let xmlFile: String = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

// works based on EUR reference currency

class CurrencyConverter: NSObject, XMLParserDelegate {
    
    // variables
    private var elementName: String = String()
    private var currency = String()
    private var rate = String()
    private var lastUpdate = String()

    // init functions
    override init(){
        super.init()
        
        // add EUR to list since we only get values from EUR to xxx and EUR is not included
        let euro = Cube(currency: "EUR", rate: "1.0")
        cubes.append(euro)
        
        let xmlFileURL = URL(string: xmlFile)
        
        let parser = XMLParser(contentsOf: xmlFileURL!)
        let xmlDic = self
        parser!.delegate = xmlDic
        if parser!.parse()
        {
            print("XML Parsing OK")
            
            lastUpdate = Date().toString(withFormat: "dd-MMM-yyyy")
            
            //print(cubes)
            //print(cubes.count)
            
            // store currency data into file for offline use
            let encoder = JSONEncoder()
            if let jsondata = try? encoder.encode(cubes),
                let jsonstr = String(data: jsondata, encoding: .utf8){
                //print(jsonstr)
                
                let filePath = getDocumentsDirectory().appendingPathComponent(fileName)

                do {
                    try jsonstr.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                    print("Writing JSON file failed!")
                }
            }
        }
        else
        {
            // something went wrong, XML format or network problems might occur
            //print("XML Parser error: ", parser!.parserError!, ", line: ", parser!.lineNumber, ", column: ", parser!.columnNumber);
            
            if let contents = readData(fileName: fileName){
                // decode from JSON
                let decoder = JSONDecoder()
                cubes.removeAll()
                let jsonData = contents.data(using: .utf8)!
                if let cubeCopy = try? decoder.decode([Cube].self, from: jsonData){
                    print(cubeCopy)
                    cubes = cubeCopy
                    lastUpdate = "offline usage, no network"
                }
            }
        }
    }
    
    // read file as string
    internal func readData(fileName: String) -> String?{
        
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pathURL = docPath.appendingPathComponent(fileName)
        
        do {
            let contents = try String(contentsOfFile: pathURL.path, encoding: .utf8)
            //contents = cleanRows(file: contents)
            return contents
            
        } catch {
            print("File Read Error for file \(pathURL.absoluteString)", error)
            
            return nil
        }
    }
    
    // functions
    
    func getLastUpdate() -> String{
        return lastUpdate
    }
    
    // list of all currencies and according rates
    func getCurrencyList() -> [Cube]{
        return cubes
    }
    
    // list of all currencies and according rates
    func getCurrencyStrings() -> [String]{
        var str: [String] = [String]()
        
        for i in cubes{
            str.append(i.currency)
        }
        
        return str.removingDuplicates()
    }
    
    // list of all currencies and according rates
    func getCurrencyArray() -> [[String]]{
        var str: [[String]] = [[String]]()
        
        for i in cubes{
            str.append([i.currency, i.currency])
        }
        
        return str.removingDuplicates()
    }
    
    // get rate based on currency
    func getRate(currency: String) -> Double{
        var rate: Double = 1.0
        
        for v in cubes{
            if v.currency == currency{
                rate = Double(v.rate)!
            }
        }
        
        return rate
    }
    
    // convert from currency A to currency B
    // 1. convert base currency to EUR
    // 2. compute EUR * dest
    func convertFromTo(baseCurrency: String, destCurrency: String) -> Double{
        let base = getRate(currency: baseCurrency)
        let dest = getRate(currency: destCurrency)
        
        let conv = 1.0 / base * dest
        return conv
    }
    
    // delegates
    internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        if elementName == "Cube" {
            if let name = attributeDict["currency"]{
                currency = name
                //print(currency)
            }
            
            if let tag = attributeDict["rate"]{
                rate = tag
                //print(rate)
            }
            
        }
        
        self.elementName = elementName
    }


    internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Cube" {
            let cube = Cube(currency: currency, rate: rate)
            cubes.append(cube)
            //print(cubes.count)
        }
    }

    
    internal func parser(_ parser: XMLParser, foundCharacters string: String) {
        //let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        //print(data)
        //print(string)
        /*if (!data.isEmpty) {
            if self.elementName == "Cube" {
                currency += data
                rate += data
            }
        } */
    }
        
    internal func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parser failure error: ", parseError)
    }
  
    internal func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

// remove dulicates from an array
extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        return reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}

// MARK: extensions
// to get string from a date
// usage: yourString = yourDate.toString(withFormat: "yyyy")
extension Date {
    func toString(withFormat format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        let myString = formatter.string(from: self)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format
        
        return formatter.string(from: yourDate!)
    }
}
