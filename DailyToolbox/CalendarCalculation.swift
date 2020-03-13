//
//  CalendarCalculation.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation
import EventKit

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
    
    func addTimeToDate(date: Date, minutes: Int) -> Date{
        let modifiedDate = Calendar.current.date(byAdding: .minute, value: minutes, to: date)
        
        return modifiedDate!
    }
    
    func addTimeToDate(date: Date, hours: Int) -> Date{
        let modifiedDate = Calendar.current.date(byAdding: .hour, value: hours, to: date)
        
        return modifiedDate!
    }
    
    // add an event to device default calendar
    func addEventToCalendar(title: String, description: String?, startDate: Date, endDate: Date, completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { () -> Void in
            let eventStore = EKEventStore()

            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if (granted) && (error == nil) {
                    let event = EKEvent(eventStore: eventStore)
                    // add alarm in seconds, -3600 = 1 Hour
                    let alarm = EKAlarm(relativeOffset: -3600.0)
                    event.title = title
                    event.startDate = startDate
                    event.endDate = endDate
                    event.notes = description
                    event.alarms = [alarm]
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    do {
                        try eventStore.save(event, span: .thisEvent)
                    } catch let e as NSError {
                        completion?(false, e)
                        return
                    }
                    completion?(true, nil)
                } else {
                    completion?(false, error as NSError?)
                }
            })
        }
    }
}
