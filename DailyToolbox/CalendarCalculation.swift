//
//  CalendarCalculation.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

class CalendarCalculation{
    
    // init
    init(){
        //
    }
    
    // number of days between start and end date
    func calculateDaysBetweenTwoDates(start: Date, end: Date) -> Int {

        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start) else {
            return 0
        }
        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end) else {
            return 0
        }
        return end - start
    }
}
