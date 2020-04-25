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
