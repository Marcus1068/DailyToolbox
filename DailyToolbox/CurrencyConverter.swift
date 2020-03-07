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

struct Cube {
    var currency: String
    var rate: String
}


// need to be declared outside of class otherwise loses values after xml parser runs
private var cubes: [Cube] = []

// works based on EUR reference currency

class CurrencyConverter: NSObject, XMLParserDelegate {
    
    // variables
    private var elementName: String = String()
    private var currency = String()
    private var rate = String()

    // init functions
    override init(){
        super.init()
        
        let xmlFileURL = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")
        
        let parser = XMLParser(contentsOf: xmlFileURL!)
        let xmlDic = self
        parser!.delegate = xmlDic
        if parser!.parse()
        {
            print("XML Parsing OK")
            print(cubes)
            print(cubes.count)
        }
        else
        {
            print("XML Parser error: ", parser!.parserError!, ", line: ", parser!.lineNumber, ", column: ", parser!.columnNumber);
        }
    }
    
    
    // functions
    
    // list of all currencies and according rates
    func getCurrencyList() -> [Cube]{
        return cubes
    }
    
    // list of all currencies and according rates
    func getCurrencyStrings() -> [String]{
        var str: [String] = [String]()
        
        str.append("EUR")
        
        for i in cubes{
            str.append(i.currency)
        }
        
        return str
    }
    
    // list of all currencies and according rates
    func getCurrencyArray() -> [[String]]{
        var str: [[String]] = [[String]]()
        
        str.append(["EUR", "EUR"])
        //str.append("EUR")
        
        for i in cubes{
            str.append([i.currency, i.currency])
        }
        
        return str
    }
    
    // get rate based on currency
    func getRate(currency: String) -> Double?{
        for v in cubes{
            if v.currency == currency{
                return Double(v.rate)!
            }
        }
        
        return nil
    }
    
    // get USD currency or fail
    func getUSDCurrency() -> Double?{
        for v in cubes{
            if v.currency == "USD"{
                return Double(v.rate)!
            }
        }
        
        return nil
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
  
}

