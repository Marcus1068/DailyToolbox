//
//  ComputeHorizon.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 24.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

class ComputeHorizon: CustomStringConvertible{
    
    // properties
    
    private var eyeLevel: Double   // in meter
    private var altitude: Double   // altitude of user in meter
    
    // computed properties
    
    var viewDistance: Double{
        get {
            return 3.57 * sqrt(eyeLevel + altitude)
        }
    }
    
    var viewDistanceToString: String{
        return String(format: "%.2f", self.viewDistance) + "km"
    }
    
    // init
    
    init(eyeLevel: Double, altitude: Double) {
        self.eyeLevel = eyeLevel
        self.altitude = altitude
    }
    
    // reduce comma value
    var description: String{
        return String(format: "%.2f", self.viewDistance) + "km"
    }
}
