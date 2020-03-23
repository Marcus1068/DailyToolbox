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
    
    // Der Prozentwert gibt Antwort auf Fragen wie:
    // „Wie viele Schüler sind 25% von 24 Schülern?“ - Gesucht: Prozentwert, gegeben: Prozenzsatz (25%) und Grundwert (24 Schüler)
    // „Wie viel sind 3% von 100 Euro?“ - Gesucht: Prozentwert, gegeben: Prozentsatz (3%) und Grundwert (100 Euro)
    var zinsen: Double
    
    var zinsenToString: String{
        return String(format: "%.2f", zinsen)
    }
    
    // Der Grundwert gibt Antwort auf Fragen wie:
    // „Wenn 6 Schüler 25% der Klasse sind, wie viele Schüler hat dann die ganze Klasse?“
    // „Wenn Sie beim Kauf eines Autos 500€ Rabatt bekommen haben und dies 15% Rabatt auf den Kaufpreis entspricht, wie hoch war dann der Kaufpreis für das Auto?“
    var kapital: Double
    
    var kapitalToString: String{
        return String(format: "%.2f", kapital)
    }
    
    // Der Prozentsatz gibt Antwort auf Fragen wie:
    // „Wie viel Prozent machen 6 Schüler von 24 Schülern aus?“
    // „Wenn der Gewinn eines Unternehmens im Vorjahr 10000€ betrug und der Gewinn dieses Jahr bei 12000€ liegt, wie viel Prozent Gewinn hat das Unternehmen erwirtschaftet?“
    // prozentsatz = prozentwert/grundwert * 100%
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
