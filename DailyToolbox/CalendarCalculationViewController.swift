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
//  CalendarCalculationViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit


class CalendarCalculationViewController: UIViewController, UIPointerInteractionDelegate {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var daysLabel: UILabel!
    @IBOutlet weak var makeCalendarButton: UIButton!
    @IBOutlet weak var christmasOutlet: UIButton!
    @IBOutlet weak var easterOutlet: UIButton!
    
    // get selected date
    var date: Date = Date()
    
    func configureView(){
        self.title = NSLocalizedString("Calendar Calculation", comment: "Calendar Calculation")
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        
        daysLabel.text = ""
        
        hideKeyboardWhenTappedAround()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: datePicker, pointerInteractionDelegate: self)
            customPointerInteraction(on: makeCalendarButton, pointerInteractionDelegate: self)
            customPointerInteraction(on: christmasOutlet, pointerInteractionDelegate: self)
            customPointerInteraction(on: easterOutlet, pointerInteractionDelegate: self)
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
    }
    
    /*
     Oster-Formel nach Carl Friedrich Gauß
     a = Jahr mod 4
     b = Jahr mod 7
     c = Jahr mod 19
     d = (19c + M) mod 30
     e = (2a + 4b + 6d + N) mod 7

     Formel für Berechnung des Ostertags:
     f = (c+11d+22e)/451

     Ostersonntag = 22+d+e-7f. Wenn dieses Ergebnis größer als 31, so liegt Ostern im April. Dann muss folgende Formel benutzt werden: Ostersonntag = 22+d+e -7f-31 = d+e-7f-9
     
     Für die Jahre 2000 bis 2099 diese beiden Konstanten mit den Werten M = 24 und N = 5 angibt
     
     https://www1.wdr.de/wissen/mensch/osterformel-gauss-100.html
     
     */
    
    func computeEasterSunday(date: Date) -> Date{
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        let M = 24
        let N = 5
        
        let a = year % 4
        let b = year % 7
        let c = year % 19
        let d = (19 * c + M) % 30
        let e = (2 * a + 4 * b + 6 * d + N) % 7
        let f = (c + 11 * d + 22 * e) / 451
        var easter = 22 + d + e - 7 * f
        
        var month: Int
        
        if easter > 31{
            month = 4
            easter -= 31
        }
        else{
            month = 3
        }
        
        // generate new date based on easter day
        let next = Calendar.current
        var easterComp = DateComponents()
        
        easterComp.day = easter
        easterComp.month = month
        easterComp.year = year
        
        let nextEaster = next.date(from: easterComp)
        
        return nextEaster!
    }
    
    
    // MARK: actions
    
    @IBAction func easterButton(_ sender: UIButton) {
        let today = Date()
        
        let easter = computeEasterSunday(date: today)
        let cal = CalendarCalculation()
        var result = cal.calculateDaysBetweenTwoDates(start: today, end: easter)
        
        if result < 0 {
            // easter has already passed in current year, compute next year
            
            let today = Date()
            
            let calendar = Calendar.current
            let todayYear = calendar.component(.year, from: today)
            
            let next = Calendar.current
            var easterComp = DateComponents()
            easterComp.year = todayYear + 1
            
            let nextEaster = next.date(from: easterComp)
            
            let easter = computeEasterSunday(date: nextEaster!)
            let cal = CalendarCalculation()
            result = cal.calculateDaysBetweenTwoDates(start: today, end: easter)
        }
        daysLabel.text = "\(result) " + NSLocalizedString("days until easter", comment: "days until easter")
    }
    
    @IBAction func christmasButton(_ sender: UIButton) {
        
        // get current year and check if christmas is over already, then year += 1
        
        let today = Date()
        
        let calendar = Calendar.current
        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)
        
        // let todayComp = DateComponents()
        
        let christmas = Calendar.current
        var christmasComp = DateComponents()
        
        if todayMonth == 12 && todayDay > 23{
            christmasComp.year! += 1
        }
        else{
            christmasComp.year = todayYear
        }
        
        christmasComp.day = 24
        christmasComp.month = 12
        
        let nextChristmas = christmas.date(from: christmasComp)
        
        let cal = CalendarCalculation()
        let result = cal.calculateDaysBetweenTwoDates(start: today, end: nextChristmas!)
        daysLabel.text = "\(result) " + NSLocalizedString("days until christmas", comment: "days until christmas")
    }
    
    @IBAction func makeCalenderAction(_ sender: UIButton) {
        let calendar = CalendarCalculation()
        
        let endDate = calendar.addTimeToDate(date: date, minutes: 30)
        
        let title = NSLocalizedString("Daily Toolbox", comment: "Daily Toolbox")
        let message = NSLocalizedString("Enter Calendar Event", comment: "Enter Calendar Event")
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addTextField()
        
        let submit = NSLocalizedString("Submit", comment: "Submit")
        let submitAction = UIAlertAction(title: submit, style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            let result = answer.text!
            let desc = NSLocalizedString("Generated by DailyToolbox App", comment: "Generated by DailyToolbox App")
            calendar.addEventToCalendar(title: result, description: desc, startDate: self.date, endDate: endDate)
        }
        
        // Create Cancel button with action handlder
        let cn = NSLocalizedString("Cancel", comment: "Cancel")
        let cancel = UIAlertAction(title: cn, style: .cancel) { (action) -> Void in
        }
        
        ac.addAction(submitAction)
        ac.addAction(cancel)
        
        self.present(ac, animated: true, completion: nil)
    }
    
    @IBAction func datePickerAction(_ sender: UIDatePicker){
        date = datePicker.date
        
        let calendar = CalendarCalculation()
        let result = calendar.calculateDaysBetweenTwoDates(start: Date(), end: date)
        daysLabel.text = "\(result) " + NSLocalizedString("days until event", comment: "days until event")
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
