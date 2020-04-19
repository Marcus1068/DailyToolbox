//
//  PowerConsumption.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 18.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

// calculate power consumption of any device
// parameters:
// price kwH in Cent
// consumption of device
// length of usage per day (in hours)
// outcome: price per day, price per month, per year
class PowerConsumption{
    
    // properties
    
    private var wattDevice: Double
    
    private var hoursOn: Double
    
    private var costPower: Double
    
    init(watt: Double, hours: Double, cost: Double) {
        wattDevice = watt
        hoursOn = hours
        costPower = cost
    }
    
    
    var computeDailyCost: Double{
        get { return wattDevice * hoursOn * costPower / 1000.0}
    }
    
    var computeMonthlyCost: Double{
        get { return computeDailyCost * 30.0}
    }
    
    var computeYearlyCost: Double{
        get { return computeMonthlyCost * 12.0}
    }
    
}
