//
//  ConvertNumbers.swift
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// umrechnen von Dezimal nach Hexadezimal und Binär
// gespeichert wird nur die Dezimalzahl, die anderen Zahlen werden berechnet

class ConvertNumbers: CustomStringConvertible{

    // properties
    var decimal: Int
    
    var hexadecimal: String{
        get { return String(decimal, radix: 16)}
        set { decimal = Int(newValue, radix: 2)!}
    }
    
    var binary: String{
        get { return String(decimal, radix: 2)}
        set { decimal = Int(newValue, radix: 16)!}
    }

    init(decimal: Int){
        self.decimal = decimal
    }
    
    init(hexadecimal: String){
        self.decimal = Int(hexadecimal, radix: 16)!
    }
    
    init(binary: String){
        self.decimal = Int(binary, radix: 2)!
    }
    
    var description: String{
        return "decimal: \(self.decimal), hexadecimal: \(self.hexadecimal), binary: \(self.binary)"
    }
}
