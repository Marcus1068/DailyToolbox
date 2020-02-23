//
//  Prozente.swift
//  swiftAG
//
//  Created by Marcus Deuß on 16.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

//
class Percent{
   
    // Eigenschaften
    
    // Der Prozentwert gibt Antwort auf Fragen wie:
    // „Wie viele Schüler sind 25% von 24 Schülern?“ - Gesucht: Prozentwert, gegeben: Prozenzsatz (25%) und Grundwert (24 Schüler)
    // „Wie viel sind 3% von 100 Euro?“ - Gesucht: Prozentwert, gegeben: Prozentsatz (3%) und Grundwert (100 Euro)
    var prozentwert: Double     // prozentwert = prozentsatz * grundwert / 100%
    
    var prozentWertToString: String{
        return String(format: "%.2f", prozentwert)
    }
    
    // Der Grundwert gibt Antwort auf Fragen wie:
    // „Wenn 6 Schüler 25% der Klasse sind, wie viele Schüler hat dann die ganze Klasse?“
    // „Wenn Sie beim Kauf eines Autos 500€ Rabatt bekommen haben und dies 15% Rabatt auf den Kaufpreis entspricht, wie hoch war dann der Kaufpreis für das Auto?“
    var grundwert: Double       // grundwert = prozentwert/prozentsatz * 100%
    
    var grundWertToString: String{
        return String(format: "%.2f", grundwert)
    }
    
    // Der Prozentsatz gibt Antwort auf Fragen wie:
    // „Wie viel Prozent machen 6 Schüler von 24 Schülern aus?“
    // „Wenn der Gewinn eines Unternehmens im Vorjahr 10000€ betrug und der Gewinn dieses Jahr bei 12000€ liegt, wie viel Prozent Gewinn hat das Unternehmen erwirtschaftet?“
    // prozentsatz = prozentwert/grundwert * 100%
    var prozentsatz: Double
    
    var prozentSatzToString: String{
        return String(format: "%.2f", prozentsatz)
    }
    
    // Grundwert ermitteln
    init(prozentwert: Double, prozentsatz: Double){
        self.prozentwert = prozentwert
        self.prozentsatz = prozentsatz
        self.grundwert = prozentwert / prozentsatz * 100.0
    }
    
    // Prozensatz ermitteln
    init(prozentwert: Double, grundwert: Double){
        self.prozentwert = prozentwert
        self.grundwert = grundwert
        self.prozentsatz = prozentwert / grundwert * 100.0
    }
    
    // Prozenzwert ermitteln
    init(prozentsatz: Double, grundwert: Double){
        self.prozentsatz = prozentsatz
        self.grundwert = grundwert
        self.prozentwert = prozentsatz * grundwert / 100.0
    }
    
}
