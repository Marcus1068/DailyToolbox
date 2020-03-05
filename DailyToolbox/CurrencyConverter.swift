//
//  CurrencyConverter.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

struct CurrencyCube {
    var currency: String
    var rate: String
}

class CurrencyConverter: NSObject, XMLParserDelegate {
    var currency: String
    var rate: String

    override init(){
        currency = ""
        rate = ""
    }
    
  /*  class func requestCurrency(completionHandler: @escaping (String?, String?, Error?) -> Void) {
        let url = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")!
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error)
                }
                return
            }

            let delegate = CurrencyConverter()
            let parser = XMLParser(data: data)
            parser.delegate = delegate
            DispatchQueue.main.async {
                completionHandler(delegate.currency, delegate.rate, parser.parserError)
            }
        }
        task.resume()
    } */
}

