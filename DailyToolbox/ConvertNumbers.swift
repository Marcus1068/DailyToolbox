//
//  ConvertNumbers.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// compute decimal to hexadecimal and binary and back
// compute decimal to roman numbers and vice versa

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

    // computed properties
    var decimalToString: String{
        return String(decimal)
    }
    
    // init functions
    
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
    
    // from decimal to roman numbers
    var decimalToRoman: String{
        
        // first step: deconstruct integer to single digits
        let arr = decimal.digits
        
        for i in arr{
            print(i)
        }
        
        return ""
    }
    
    var romanToDecimal: Int{
        return 0
    }
}

// deconstruct decimal number as array of digits
extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { Int(String($0)) }
    }
}
