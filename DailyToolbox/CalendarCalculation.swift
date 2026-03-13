/*

Copyright 2020-2026 Marcus Deuß

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
//  CalendarCalculation.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation
import EventKit

class CalendarCalculation {
    
    // init
    init() {
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
    
    func addTimeToDate(date: Date, minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: date) ?? date
    }
    
    func addTimeToDate(date: Date, hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: date) ?? date
    }
    
    // add an event to device default calendar
    func addEventToCalendar(title: String, description: String?, startDate: Date, endDate: Date) async throws {
        let eventStore = EKEventStore()
        let granted = try await eventStore.requestFullAccessToEvents()
        guard granted else {
            throw CalendarError.accessDenied
        }
        let event = EKEvent(eventStore: eventStore)
        // add alarm in seconds, -3600 = 1 Hour
        let alarm = EKAlarm(relativeOffset: -3600.0)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = description
        event.alarms = [alarm]
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }
}

enum CalendarError: Error {
    case accessDenied
}
