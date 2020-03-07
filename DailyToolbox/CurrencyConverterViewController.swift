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
    var currencyList: [[String]] = [[String]]()
    
    
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    
    
    func configureView() {
        
        self.title = "Currency Converter"
        
        fromTextField.becomeFirstResponder()
        fromTextField.text = "1.0"

        numberOfCurrencies = cvt.getCurrencyArray().count
        
        currencyList = cvt.getCurrencyArray()
        
        // Connect data:
        self.currencyPicker.delegate = self
        self.currencyPicker.dataSource = self
        
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
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfCurrencies
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return currencyList[row][component]
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        fromLabel.text = currencyList[row][0]
        toLabel.text = currencyList[row][1]
        
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
