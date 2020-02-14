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
            let num = Zahlen(dezimal: input)
            hexaTextField.text = num.hexadezimal.uppercased()
            binaryTextField.text = num.binär
        }
        else{
            hexaTextField.text = ""
            binaryTextField.text = ""
        }
    }
    
    @objc func hexaTextFieldDidChange(_ textField: UITextField) {
        decimalTextField.text = textField.text
        binaryTextField.text = textField.text
    }
    
    @objc func binaryTextFieldDidChange(_ textField: UITextField) {
        decimalTextField.text = textField.text
        hexaTextField.text = textField.text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureView()
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
