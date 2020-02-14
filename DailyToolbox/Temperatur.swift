//
//  Temperatur.swift
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// die Klasse rechnet von Kelvin nach Fahrenheit und Celsius, intern wird alles in Kelvin gespeichert
class Temperatur: CustomStringConvertible{
    
    // Eigenschaften
    var kelvin: Double
    
    // berchnete Eigenschaften
    var celsius: Double{
        get { return kelvin - 273.15}
        set { kelvin = newValue + 273.15}
    }
    
    var fahrenheit: Double{
        get { return celsius * 1.8 + 32.0}
        set { kelvin = (newValue - 32.0) / 1.8 + 273.15}
    }
    
    // Init Funktionen
    init(kelvin: Double){
        self.kelvin = kelvin
    }
    
    init(celsius: Double){
        self.kelvin = celsius + 273.15
    }
    
    init(fahrenheit: Double){
        self.kelvin = (fahrenheit - 32.0) / 1.8 + 273.15
    }
    
    var description: String{
        return "Celsius: \(self.celsius), Fahrenheit: \(self.fahrenheit), Kelvin: \(self.kelvin)"
    }
    
}
