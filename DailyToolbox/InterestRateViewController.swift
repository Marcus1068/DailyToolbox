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
//  InterestRateViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 12.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class InterestRateViewController: UIViewController, UITextFieldDelegate, UIPointerInteractionDelegate {

    @IBOutlet weak var interestTextField: UITextField!
    @IBOutlet weak var capitalTextField: UITextField!
    @IBOutlet weak var interestRateTextField: UITextField!
    
    @IBOutlet weak var calculateButton: UIButton!
    
    
    func configureView() {
        self.title = NSLocalizedString("Interest Rate calculation", comment: "Interest Rate calculation")
        
        //interestTextField.text = NSLocalizedString("Interest", comment: "Interest")
        //capitalTextField.text = NSLocalizedString("Capital", comment: "Capital")
        //interestRateTextField.text = NSLocalizedString("Interest rate", comment: "Interest rate")
        
        hideKeyboardWhenTappedAround()
        
        interestTextField.becomeFirstResponder()
        
        interestTextField.delegate = self
        capitalTextField.delegate = self
        interestRateTextField.delegate = self
        
        interestTextField.addTarget(self, action: #selector(InterestRateViewController.interestTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        capitalTextField.addTarget(self, action: #selector(InterestRateViewController.capitalTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        interestRateTextField.addTarget(self, action: #selector(InterestRateViewController.interestRateTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
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
    
    @objc func interestTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            
        }
        else{
            capitalTextField.text = ""
            interestRateTextField.text = ""
        }
    }

    @objc func capitalTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            
        }
        else{
            interestTextField.text = ""
            interestRateTextField.text = ""
        }
    }
    
    @objc func interestRateTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            
        }
        else{
            capitalTextField.text = ""
            interestTextField.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == interestTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == capitalTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == interestRateTextField{
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

    // MARK: actions
    @IBAction func calculateAction(_ sender: UIButton) {
        if interestTextField.text!.count > 0 && capitalTextField.text!.count > 0 {
            let z : Double = Double(interestTextField.text!)!
            let k : Double = Double(capitalTextField.text!)!
            let str = InterestRate(zinsen: z, kapital: k)
            interestRateTextField.text = str.zinssatzToString
        }
     
        if interestTextField.text!.count > 0 && interestRateTextField.text!.count > 0 {
            let z : Double = Double(interestTextField.text!)!
            let r : Double = Double(interestRateTextField.text!)!
            let str = InterestRate(zinsen: z, zinssatz: r)
            capitalTextField.text = str.kapitalToString
        }
     
        if interestRateTextField.text!.count > 0 && capitalTextField.text!.count > 0 {
            let r : Double = Double(interestRateTextField.text!)!
            let k : Double = Double(capitalTextField.text!)!
            let str = InterestRate(zinssatz: r, kapital: k)
            interestTextField.text = str.zinsenToString
        }
    }
    
}
