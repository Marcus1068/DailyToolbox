//
//  CurrencyConverter.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

struct Cube {
    var currency: String
    var rate: String
}


// need to be declared outside of class otherwise loses values after xml parser runs
var cubes: [Cube] = []

// works based on EUR reference currency

class CurrencyConverter: NSObject, XMLParserDelegate {
    
    // variables
    var elementName: String = String()
    var currency = String()
    var rate = String()

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
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

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


    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Cube" {
            let cube = Cube(currency: currency, rate: rate)
            cubes.append(cube)
            //print(cubes.count)
        }
    }

    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
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
        
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parser failure error: ", parseError)
    }
  
}

