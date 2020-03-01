//
//  Benchmark.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 27.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

class Benchmark{
    
    
    // functions
    
    // calculate benchmark and return in seconds passed since start, based on Swift random
    static func benchmarkRandomNumbersSwift(range: Int) -> Float{
        let start = Date()
        
        var sum = 0
        for _ in 1...range{
            // swift4 regular random method takes about 5 times longer than arc4random
            sum += Int.random(in: 0 ..< 100)
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        //print ("Fertig nach \(seconds) Sekunden")
        //print ("Referenzwert Macbook Pro 15 Model i7 von 2015 = ca. 1.8 Sekunden im Release Mode")
        
        return Float(seconds)
    }
    
    
    // calculate benchmark and return in seconds passed since start, based on C arc4random method
    static func benchmarkRandomNumbersArc4(range: Int) -> Float{
        let start = Date()
        
        var sum = 0
        for _ in 1...range{
            // swift4 regular random method takes about 5 times longer than arc4random
            // sum += Int.random(in: 0 ..< 100)
            sum += Int(arc4random_uniform(100))
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        //print ("Fertig nach \(seconds) Sekunden")
        //print ("Referenzwert Macbook Pro 15 Model i7 von 2015 = ca. 1.8 Sekunden im Release Mode")
        
        return Float(seconds)
    }
    
    static func benchmarkString() -> Float{
        let start = Date()
        
        var s: String = "Benchmark test with Swift 5"
        
        // more than 20 times will kill ios simulator
        for _ in 1...20{
            s += s
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        //print ("Fertig nach \(seconds) Sekunden")
        //print ("Referenzwert Macbook Pro 15 Model i7 von 2015 = ca. 1.8 Sekunden im Release Mode")
        
        return Float(seconds)
    }

}
