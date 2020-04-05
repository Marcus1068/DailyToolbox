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
//  CurrencyConverterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class CurrencyConverterViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIPointerInteractionDelegate {
    
    let cvt = CurrencyConverter()
    let baseCurrency = "1.00"
    var numberOfCurrencies : Int = 0
    var currencyList: [[String]] = [[String]]()
    
    
    @IBOutlet weak var infoTextLabel: UILabel!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    
    
    func configureView() {
        
        self.title = "Currency Converter"
        
        currencyTextField.becomeFirstResponder()
        currencyTextField.delegate = self
        currencyTextField.text = baseCurrency
        resultLabel.text = baseCurrency

        numberOfCurrencies = cvt.getCurrencyArray().count
        
        currencyList = cvt.getCurrencyArray()
        
        // Connect data:
        self.currencyPicker.delegate = self
        self.currencyPicker.dataSource = self
        
        // preselect USD as destination
        currencyPicker.selectRow(1, inComponent: 1, animated: true)
        
        currencyTextField.addTarget(self, action: #selector(CurrencyConverterViewController.currencyTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        lastUpdateLabel.text = cvt.getLastUpdate()
        
        hideKeyboardWhenTappedAround()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: currencyPicker, pointerInteractionDelegate: self)
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
        
    }
    
    @objc func currencyTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            var result = cvt.convertFromTo(baseCurrency: fromLabel.text!, destCurrency: toLabel.text!)
            result = result * Double(currencyTextField.text!)!
            resultLabel.text = String(format: "%.2f", result)
        }
        else{
            resultLabel.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == currencyTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfCurrencies
    }
    
    /*
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0{
            fromLabel.text = currencyList[row][0]
            return currencyList[row][0]
        }
        else{
            toLabel.text = currencyList[row][1]
            return currencyList[row][1]
        }
    } */
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        
        var result = cvt.convertFromTo(baseCurrency: fromLabel.text!, destCurrency: toLabel.text!)
        result = result * Double(currencyTextField.text!)!
        resultLabel.text = String(format: "%.2f", result)
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {

        if component == 0{
            fromLabel.text = currencyList[row][0]
            var title = UILabel()
             if let view = view {
                    title = view as! UILabel
              }
            
            title.font = UIFont(name: "HelveticaNeue", size: 35)
            title.textColor = UIColor.blue
            title.text =  currencyList[row][0]
            title.textAlignment = .center

            return title
        }
        else{
            toLabel.text = currencyList[row][1]
            var title = UILabel()
             if let view = view {
                    title = view as! UILabel
              }
            
            title.font = UIFont(name: "HelveticaNeue", size: 35)
            title.textColor = UIColor.blue
            title.text =  currencyList[row][1]
            title.textAlignment = .center

            return title
        }

    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36.0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 300
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
