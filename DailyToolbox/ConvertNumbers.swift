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
    private var decimal: Int = 0
    
    private var roman: String = String()
    
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
    
    init(roman: String){
        self.roman = roman
    }
    
    var description: String{
        return "decimal: \(self.decimal), hexadecimal: \(self.hexadecimal), binary: \(self.binary)"
    }
    
    // from decimal to roman numbers
    var decimalToRoman: String{
        
        var result: String = String()
        
        // first step: deconstruct integer to single digits
        var arr = decimal.digits

        // fill array with 4 digits in case (leading 0s)
        if arr.count < 4{
            let diff = 4 - arr.count
            for _ in 1...diff{
                arr.insert(0, at: 0)
            }
        }
        
        for i in 1...4{
            switch(i){
                
            case 1: // M = 1000
                result += result + String(repeating: "M", count: arr[0])
                
            case 2: // C = 100
                switch(arr[1]){
                case 9:
                    result += "CM"
                case 6..<9:
                    result += "D" + String(repeating: "C", count: arr[1] - 5)
                case 5:
                    result += "D"
                case 4:
                    result += "CD"
                case 1..<4:
                    result += String(repeating: "C", count: arr[1])
                case 0:
                    result += ""
                default:
                    result = "something went wrong with 100"
                }
                
            case 3: // X = 10
                switch(arr[2]){
                case 9:
                    result += "XC"
                case 5..<9:
                    result += "L" + String(repeating: "X", count: arr[2] - 5)
                case 4:
                    result += "XL"
                case 1..<4:
                    result += String(repeating: "X", count: arr[2])
                case 0:
                    result += ""
                default:
                    result = "something went wrong with 10"
                }
                
            case 4: // I = 1
                switch(arr[3]){
                case 1..<4:
                    result += String(repeating: "I", count: arr[3])
                case 4:
                    result += "IV"
                case 5:
                    result += "V"
                case 6..<9:
                    result += "V" + String(repeating: "I", count: arr[3] - 5)
                case 9:
                    result += "IX"
                case 0:
                    result += ""
                default:
                    result = "something went wrong with 1"
                }
                
            case 5:
                result = "number to big, max 3999"
                
            default:
                result = "not implemented yet"
            }
        }
        
        //print(result)
        
        return result
    }
    
    var romanToDecimal: Int{
        
        var result: Int = 0
        
        // first step: deconstruct string to single digits
        var arr = Array(roman)
        
        while arr.count > 0{
        
            if arr.count >= 2{
                let a = arr[0]
                let b = arr[1]
                
                if a == "I" && b == "V"{
                    result += 4
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
                
                if a == "I" && b == "X"{
                    result += 9
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
                
                if a == "X" && b == "L"{
                    result += 40
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
                
                if a == "X" && b == "C"{
                    result += 90
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
                
                if a == "C" && b == "D"{
                    result += 400
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
                
                if a == "C" && b == "M"{
                    result += 900
                    
                    arr.remove(at: 0)
                    arr.remove(at: 0)
                    continue
                }
            }
            
            
            switch(arr[0]){
            case "M":
                result += 1000
                arr.remove(at: 0)
            case "D":
                result += 500
                arr.remove(at: 0)
            case "C":
                result += 100
                arr.remove(at: 0)
            case "L":
                result += 50
                arr.remove(at: 0)
            case "X":
                result += 10
                arr.remove(at: 0)
            case "V":
                result += 5
                arr.remove(at: 0)
            case "I":
                result += 1
                arr.remove(at: 0)
            default:
                // error
                result = 0
            }
            
        }
        
        return result
    }
    
}

// deconstruct decimal number as array of digits
extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { Int(String($0)) }
    }
}
