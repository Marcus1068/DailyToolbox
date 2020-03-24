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
//  InterestRate.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

class InterestRate{
    // Eigenschaften
    
    // https://www.gut-erklaert.de/mathematik/zinsrechnung-formeln-beispiele.html
    
    var zinsen: Double
    
    var zinsenToString: String{
        return String(format: "%.2f", zinsen)
    }
    
    var kapital: Double
    
    var kapitalToString: String{
        return String(format: "%.2f", kapital)
    }
    
    var zinssatz: Double
    
    var zinssatzToString: String{
        return String(format: "%.2f", zinssatz)
    }
    
    // Kapital ermitteln
    init(zinsen: Double, zinssatz: Double){
        self.zinsen = zinsen
        self.zinssatz = zinssatz
        self.kapital = zinsen / zinssatz * 100.0
    }
    
    // Zinssatz in % ermitteln
    init(zinsen: Double, kapital: Double){
        self.zinsen = zinsen
        self.kapital = kapital
        self.zinssatz = zinsen / kapital * 100.0
    }
    
    // Zinswert ermitteln
    init(zinssatz: Double, kapital: Double){
        self.zinssatz = zinssatz
        self.kapital = kapital
        self.zinsen = zinssatz * kapital / 100.0
    }
    
}
