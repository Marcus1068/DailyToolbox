/*

Copyright 2020 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  Temperature.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 13.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// die Klasse rechnet von Kelvin nach Fahrenheit und Celsius, intern wird alles in Kelvin gespeichert
class Temperature: CustomStringConvertible{
    
    // properties
    var kelvin: Double
    
    
    // computed properties
    
    var kelvinToString: String{
        return String(format: "%.2f", kelvin)
    }
    
    var celsius: Double{
        get { return kelvin - 273.15}
        set { kelvin = newValue + 273.15}
    }
    
    var celsiusToString: String{
        return String(format: "%.2f", celsius)
    }
    
    var fahrenheit: Double{
        get { return celsius * 1.8 + 32.0}
        set { kelvin = (newValue - 32.0) / 1.8 + 273.15}
    }
    
    var fahrenheitToString: String{
        return String(format: "%.2f", fahrenheit)
    }
    
    // Init functions
    init(kelvin: Double){
        self.kelvin = kelvin
    }
    
    init(celsius: Double){
        self.kelvin = celsius + 273.15
    }
    
    init(fahrenheit: Double){
        self.kelvin = (fahrenheit - 32.0) / 1.8 + 273.15
    }
    
    // string description for using print(Temparature)
    var description: String{
        return "Celsius: \(self.celsius), Fahrenheit: \(self.fahrenheit), Kelvin: \(self.kelvin)"
    }
    
}
