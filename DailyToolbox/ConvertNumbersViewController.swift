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
        
        self.decimalTextField.becomeFirstResponder()
        
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
            hexaTextField.text = num.hexadecimal
        }
        else{
            decimalTextField.text = ""
            hexaTextField.text = ""
        }
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
