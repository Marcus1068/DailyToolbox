//
//  DecimalRomanNumbersViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 13.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class DecimalRomanNumbersViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var decimalTextField: UITextField!
    @IBOutlet weak var romanTextField: UITextField!
    
    func configureView(){
        self.title = "Roman number conversion"
        
        decimalTextField.becomeFirstResponder()
        
        decimalTextField.delegate = self
        
        decimalTextField.addTarget(self, action: #selector(DecimalRomanNumbersViewController.decimalTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)

        romanTextField.delegate = self
        
        romanTextField.addTarget(self, action: #selector(DecimalRomanNumbersViewController.romanTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)

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
            textField.text = textField.text?.uppercased()
            
            // check that not more than three identical characters entered
            let check = textField.text!
            let chars = Array(check)
            if check.count > 3{
                if chars[0] == chars[1] && chars[1] == chars[2] && chars[2] == chars[3]{
                    textField.text = String(repeating: chars[0], count: 3)
                }
            }
            
            let conv = ConvertNumbers(roman: textField.text!)
            
            decimalTextField.text = String(conv.romanToDecimal)
        }
        else{
            decimalTextField.text = ""
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
