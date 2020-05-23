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
//  PowerConsumptionViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 18.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class PowerConsumptionViewController: UIViewController, UITextFieldDelegate, UIPointerInteractionDelegate {

    
    @IBOutlet weak var costPerKwhTextField: UITextField!
    @IBOutlet weak var hoursOnTextField: UITextField!
    @IBOutlet weak var wattDeviceTextField: UITextField!
    
    @IBOutlet weak var dailyCostLabel: UILabel!
    @IBOutlet weak var monthlyCostLabel: UILabel!
    @IBOutlet weak var yearlyCostLabel: UILabel!
    
    @IBOutlet weak var calculateButton: UIButton!
    
    func configureView() {
    
        //detailItem = true
        self.title = NSLocalizedString("Power Consumption Calculation", comment: "Power Consumption Calculation")
        
        costPerKwhTextField.becomeFirstResponder()
        
        costPerKwhTextField.delegate = self
        hoursOnTextField.delegate = self
        wattDeviceTextField.delegate = self
        
        dailyCostLabel.text = "0.0 €"
        monthlyCostLabel.text = "0.0 €"
        yearlyCostLabel.text = "0.0 €"
        
        
        costPerKwhTextField.addTarget(self, action: #selector(PowerConsumptionViewController.costPerKwhTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        hoursOnTextField.addTarget(self, action: #selector(PowerConsumptionViewController.hoursOnTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        wattDeviceTextField.addTarget(self, action: #selector(PowerConsumptionViewController.wattDeviceTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        hideKeyboardWhenTappedAround()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: calculateButton, pointerInteractionDelegate: self)
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureView()
    }
    

    @objc func costPerKwhTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            /*let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            percentValueTextField.text = num.hexadecimal.uppercased()
            baseValueTextField.text = num.binary */
        }
        else{
            //percentValueTextField.text = ""
            //baseValueTextField.text = ""
        }
    }
    
    @objc func hoursOnTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : Int = Int(textField.text!)!
            if input > 24{
                textField.text = "24"
            }
        }
        else{
            //percentValueTextField.text = ""
            //baseValueTextField.text = ""
        }
    }
    
    @objc func wattDeviceTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            /*let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            percentValueTextField.text = num.hexadecimal.uppercased()
            baseValueTextField.text = num.binary */
        }
        else{
            //percentValueTextField.text = ""
            //baseValueTextField.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == costPerKwhTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == hoursOnTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == wattDeviceTextField{
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func calculateAction(_ sender: Any) {
        let ok = NSLocalizedString("OK", comment: "OK")
        
        guard costPerKwhTextField.text!.count > 0 else {
            let title = NSLocalizedString("Cost value missing", comment: "Cost value missing")
            let message = NSLocalizedString("Enter kwH cost", comment: "Enter kwH cost")
            
            displayAlert(title: title, message: message, buttonText: ok)
            return
        }
        
        guard hoursOnTextField.text!.count > 0 else {
            let title = NSLocalizedString("Hours missing", comment: "Hours missing")
            let message = NSLocalizedString("Enter number of hours", comment: "Enter number of hours")
            displayAlert(title: title, message: message, buttonText: ok)
            return
        }
        guard wattDeviceTextField.text!.count > 0 else {
            let title = NSLocalizedString("Watt value missing", comment: "Watt value missing")
            let message = NSLocalizedString("Enter Watt", comment: "Enter Watt")
            displayAlert(title: title, message: message, buttonText: ok)
            return
        }
        

        let w : Double = Double(wattDeviceTextField.text!)!
        
        let h : Double = Double(hoursOnTextField.text!)!
        
        let c : Double = Double(costPerKwhTextField.text!)!
        
        let compute = PowerConsumption(watt: w, hours: h, cost: c)
        
        dailyCostLabel.text = String(format: "%.3f", compute.computeDailyCost) + " €"
        monthlyCostLabel.text = String(format: "%.2f", compute.computeMonthlyCost) + " €"
        yearlyCostLabel.text = String(format: "%.2f", compute.computeYearlyCost) + " €"
    
    }
    
}
