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
//  ComputeNumbersViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class ConvertNumbersViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var decimalTextField: UITextField!
    @IBOutlet weak var hexaTextField: UITextField!
    @IBOutlet weak var binaryTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureView()
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = NSLocalizedString("Convert Numbers", comment: "Convert Numbers")
        
        decimalTextField.becomeFirstResponder()
        
        decimalTextField.delegate = self
        hexaTextField.delegate = self
        binaryTextField.delegate = self
        
        decimalTextField.addTarget(self, action: #selector(ConvertNumbersViewController.decimalTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        hexaTextField.addTarget(self, action: #selector(ConvertNumbersViewController.hexaTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        binaryTextField.addTarget(self, action: #selector(ConvertNumbersViewController.binaryTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        hideKeyboardWhenTappedAround()
    }
    
    @objc func decimalTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : Int = Int(textField.text!)!
            let value = ConvertNumbers(decimal: input)
            hexaTextField.text = value.hexadecimal.uppercased()
            binaryTextField.text = value.binary
        }
        else{
            hexaTextField.text = ""
            binaryTextField.text = ""
        }
    }
    
    @objc func hexaTextFieldDidChange(_ textField: UITextField) {
        // allow only uppercase hex letters
        textField.text = textField.text?.uppercased()
        if textField.text!.count > 0{
            let input : String = textField.text!
            let value = ConvertNumbers(hexadecimal: input)
            decimalTextField.text = value.decimalToString
            binaryTextField.text = value.binary
        }
        else{
            decimalTextField.text = ""
            binaryTextField.text = ""
        }
    }
    
    @objc func binaryTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : String = textField.text!
            let value = ConvertNumbers(binary: input)
            decimalTextField.text = value.decimalToString
            hexaTextField.text = value.hexadecimal.uppercased()
        }
        else{
            decimalTextField.text = ""
            hexaTextField.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == decimalTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == hexaTextField{
            switch(string){
            case "a", "A", "b", "B", "c", "C", "d", "D", "e", "E", "f", "F":
                return true
                
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == binaryTextField{
            switch(string){
            case "0", "1":
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
    
    
}
