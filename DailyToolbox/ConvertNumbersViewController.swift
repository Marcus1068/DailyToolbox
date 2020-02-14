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
        
        self.title = "Convert Numbers"
        
        decimalTextField.becomeFirstResponder()
        
        decimalTextField.delegate = self
        hexaTextField.delegate = self
        binaryTextField.delegate = self
        
        decimalTextField.addTarget(self, action: #selector(ConvertNumbersViewController.decimalTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        hexaTextField.addTarget(self, action: #selector(ConvertNumbersViewController.hexaTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        binaryTextField.addTarget(self, action: #selector(ConvertNumbersViewController.binaryTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    @objc func decimalTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            hexaTextField.text = num.hexadecimal.uppercased()
            binaryTextField.text = num.binary
        }
        else{
            hexaTextField.text = ""
            binaryTextField.text = ""
        }
    }
    
    @objc func hexaTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : String = textField.text!
            let num = ConvertNumbers(hexadecimal: input)
            decimalTextField.text = String(num.decimal)
            binaryTextField.text = num.binary
        }
        else{
            decimalTextField.text = ""
            binaryTextField.text = ""
        }
    }
    
    @objc func binaryTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            let input : String = textField.text!
            let num = ConvertNumbers(binary: input)
            decimalTextField.text = String(num.decimal)
            hexaTextField.text = num.hexadecimal.uppercased()
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
