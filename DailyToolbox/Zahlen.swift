//
//  Zahlen.swift
//  swiftAG
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// umrechnen von Dezimal nach Hexadezimal und Binär
// gespeichert wird nur die Dezimalzahl, die anderen Zahlen werden berechnet

class Zahlen: CustomStringConvertible{

    // Eigenschaften
    var dezimal: Int
    
    var hexadezimal: String{
        get { return String(dezimal, radix: 16)}
        set { dezimal = Int(newValue, radix: 2)!}
    }
    
    var binär: String{
        get { return String(dezimal, radix: 2)}
        set { dezimal = Int(newValue, radix: 16)!}
    }

    init(dezimal: Int){
        self.dezimal = dezimal
    }
    
    init(hexadezimal: String){
        self.dezimal = Int(hexadezimal, radix: 16)!
    }
    
    init(binär: String){
        self.dezimal = Int(binär, radix: 2)!
    }
    
    var description: String{
        return "Dezimal: \(self.dezimal), Hexadezimal: \(self.hexadezimal), Binär: \(self.binär)"
    }
}
