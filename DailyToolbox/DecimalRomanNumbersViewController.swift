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
//  DecimalRomanNumbersViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 13.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class DecimalRomanNumbersViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var infoText: UITextView!
    @IBOutlet weak var decimalTextField: UITextField!
    @IBOutlet weak var romanTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    func configureView(){
        self.title = NSLocalizedString("Roman number conversion", comment: "Roman number conversion")
        
        decimalTextField.becomeFirstResponder()
        
        decimalTextField.delegate = self
        
        decimalTextField.addTarget(self, action: #selector(DecimalRomanNumbersViewController.decimalTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)

        romanTextField.delegate = self
        
        romanTextField.addTarget(self, action: #selector(DecimalRomanNumbersViewController.romanTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        statusLabel.text = ""
        
        hideKeyboardWhenTappedAround()
        
        // help text
        var fileName : String
        
        switch Local.currentLocaleForDate(){
        case "de_DE", "de_AT", "de_CH", "de":
            fileName = "Roman german"
            break
            
        default: // all other languages get english privacy statement
            fileName = "Roman english"
            break
        }
        
        infoText.attributedText = Global.getRTFFileFromBundle(fileName: fileName)

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
    }
    
    @objc func decimalTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let conv = ConvertNumbers(decimal: Int(textField.text!)!)
            romanTextField.text = conv.decimalToRoman
        }
        else{
            romanTextField.text = ""
        }
    }
    
    @objc func romanTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            statusLabel.text = ""
            
            textField.text = textField.text?.uppercased()
            
            // check that not more than three identical characters entered
            let check = textField.text!
            var chars = Array(check)
            var count = chars.count
            
            // check for repeating chars
            if check.count > 3{         // I I I I = 0 1 2 3 count = 4
                if chars[count - 4] == chars[count - 3] && chars[count - 3] == chars[count - 2] && chars[count - 2] == chars[count - 1]{
                    let more = NSLocalizedString("More than three", comment: "More than three")
                    let allowed = NSLocalizedString("not allowed", comment: "not allowed")
                    statusLabel.text = more + " \(chars[count - 4]) " + allowed
                    chars.removeLast()
                    textField.text = String(chars)
                    count -= 1
                }
            }
        
            // check for correct order
            // M = 1000, D = 500, C = 100, L = 50, X = 10, V = 5, I = 1
            // IM, ID, IC, IL not allowed, remove last char
            // XD, XM not allowed, remove last char
            // DM not allowed
            // CMM not allowed
            //
            
            if check.count > 1{
                var lastChars : String = ""
                lastChars.append(chars[count - 2])
                lastChars.append(chars[count - 1])
                switch lastChars{
                case "IM", "ID", "IC", "IL", "XD", "XM", "DM", "VV", "DD", "LL", "LD", "LM", "VC", "VM", "VD", "VL", "LC", "VX":
                    statusLabel.text = "\(lastChars) " + NSLocalizedString("not allowed", comment: "not allowed")
                    chars.removeLast()
                    textField.text = String(chars)
                    count -= 1
                    
                default:
                    break
                }
            }
            
            let conv = ConvertNumbers(roman: textField.text!)
            decimalTextField.text = String(conv.romanToDecimal)
            
            // validate with opposite conversion
            let validate = ConvertNumbers(decimal: Int(decimalTextField.text!)!)
            if validate.decimalToRoman != textField.text!{
                let err = NSLocalizedString("Error", comment: "Error")
                let correct = NSLocalizedString("correct", comment: "correct")
                statusLabel.text = err + " :\(validate.decimalToRoman) != \(textField.text!), " + correct + ":\(validate.decimalToRoman)"
                textField.text = validate.decimalToRoman
            }
            
        }
        else{
            decimalTextField.text = ""
            statusLabel.text = ""
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
        
        if textField == romanTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                return true
                
            case "i", "I", "v", "V", "x", "X", "l", "L", "d", "D", "c", "C", "m", "M":
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
