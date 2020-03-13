//
//  CalendarCalculationViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class CalendarCalculationViewController: UIViewController {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var daysLabel: UILabel!
    
    // get selected date
    var date: Date = Date()
    
    func configureView(){
        self.title = "Calendar Calculation"
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        
        daysLabel.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
    }
    
    @IBAction func makeCalenderButton(_ sender: UIButton) {
        let calendar = CalendarCalculation()
        
        let endDate = calendar.addTimeToDate(date: date, minutes: 30)
        
        calendar.addEventToCalendar(title: "Testeintrag", description: "Beschreibung", startDate: date, endDate: endDate)
    }
    
    @IBAction func datePickerAction(_ sender: UIDatePicker) {
        date = datePicker.date
        
        let calendar = CalendarCalculation()
        let result = calendar.calculateDaysBetweenTwoDates(start: Date(), end: date)
        daysLabel.text = "\(result) days until event"
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
