//
//  CurrencyConverterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class CurrencyConverterViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let cvt = CurrencyConverter()
    var numberOfCurrencies : Int = 0
    var fromCurrencyList: [String] = []
    var toCurrencyList: [String] = []
    
    
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var fromCurrencyPicker: UIPickerView!
    @IBOutlet weak var toCurrencyPicker: UIPickerView!
    @IBOutlet weak var toTextField: UITextField!
    
    
    func configureView() {
        
        self.title = "Currency Converter"
        
        fromTextField.becomeFirstResponder()
        fromTextField.text = "1"

        numberOfCurrencies = cvt.getCurrencyStrings().count
        
        fromCurrencyList = cvt.getCurrencyStrings()
        toCurrencyList = cvt.getCurrencyStrings()
        
        // Connect data:
        self.fromCurrencyPicker.delegate = self
        self.fromCurrencyPicker.dataSource = self
        self.toCurrencyPicker.delegate = self
        self.toCurrencyPicker.dataSource = self
        
        if let dollar = cvt.getUSDCurrency(){
            print(dollar)
        }
        
        let cur = cvt.getCurrencyList()
        
        for i in cur{
            print("Währung: \(i.currency), Kurs: \(i.rate)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        
        return numberOfCurrencies
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch(pickerView){
        case fromCurrencyPicker:
            return fromCurrencyList[row]
        case toCurrencyPicker:
            return toCurrencyList[row]
        default:
            return fromCurrencyList[row]
        }
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
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
