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
//  TemperatureViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class TemperatureViewController: UIViewController, UITextFieldDelegate{
  
    @IBOutlet weak var celsiusTextField: UITextField!
    @IBOutlet weak var fahrenheitTextField: UITextField!
    @IBOutlet weak var kelvinTextField: UITextField!
    
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = NSLocalizedString("Temperature Calculation", comment: "Temperature Calculation")
        
        celsiusTextField.becomeFirstResponder()
        
        celsiusTextField.delegate = self
        fahrenheitTextField.delegate = self
        kelvinTextField.delegate = self
        
        celsiusTextField.addTarget(self, action: #selector(TemperatureViewController.celsiusTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        fahrenheitTextField.addTarget(self, action: #selector(TemperatureViewController.fahrenheitTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        kelvinTextField.addTarget(self, action: #selector(TemperatureViewController.kelvinTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        hideKeyboardWhenTappedAround()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }
    
    @objc func celsiusTextFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text!.replacingOccurrences(of: ",", with: ".")
        
        if textField.text!.count > 0{
            
            let input : Double = Double(textField.text!)!
            let value = Temperature(celsius: input)
            fahrenheitTextField.text = value.fahrenheitToString
            kelvinTextField.text = value.kelvinToString
        }
        else{
            fahrenheitTextField.text = ""
            kelvinTextField.text = ""
        }
    }
    
    @objc func fahrenheitTextFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text!.replacingOccurrences(of: ",", with: ".")
        
        if textField.text!.count > 0{
            let input : Double = Double(textField.text!)!
            let value = Temperature(fahrenheit: input)
            celsiusTextField.text = value.celsiusToString
            kelvinTextField.text = value.kelvinToString
        }
        else{
            celsiusTextField.text = ""
            kelvinTextField.text = ""
        }
    }
    
    @objc func kelvinTextFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text!.replacingOccurrences(of: ",", with: ".")
        
        if textField.text!.count > 0{
            let input : Double = Double(textField.text!)!
            let value = Temperature(kelvin: input)
            celsiusTextField.text = value.celsiusToString
            fahrenheitTextField.text = value.fahrenheitToString
        }
        else{
            celsiusTextField.text = ""
            fahrenheitTextField.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let allowedCharacters = CharacterSet(charactersIn:"0123456789.,").inverted
            
        let components = string.components(separatedBy: allowedCharacters)
        let filtered = components.joined(separator: "")
        
        if string == filtered {
            return true
        } else {
            return false
        }
    }

}

extension NumberFormatter {
    convenience init(style: Style) {
        self.init()
        self.numberStyle = style
    }
}
extension Formatter {
    static let currency = NumberFormatter(style: .currency)
}
extension FloatingPoint {
    var currency: String {
        return Formatter.currency.string(for: self) ?? ""
    }
}
