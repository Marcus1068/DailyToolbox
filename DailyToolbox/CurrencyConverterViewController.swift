//
//  CurrencyConverterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

struct Cube {
    var currency: String
    var rate: String
}

var cubes: [Cube] = []

class CurrencyConverterViewController: UIViewController, XMLParserDelegate {

    
    var elementName: String = String()
    var currency = String()
    var rate = String()
    
    func configureView() {
        
        self.title = "Currency Converter"
    
        let xmlFileURL = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")
        
        let parser = XMLParser(contentsOf: xmlFileURL!)
        let xmlDic = CurrencyConverterViewController()
        parser!.delegate = xmlDic
        if parser!.parse()
        {
            print("XML Parsing OK")
            print(cubes)
            print(cubes.count)
        }
        else
        {
            print("XML Parser error: ", parser!.parserError, ", line: ", parser!.lineNumber, ", column: ", parser!.columnNumber);
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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
            //let cube = Cube(currency: currency, rate: rate)
            //cubes.append(cube)
            
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
        print(string)
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
