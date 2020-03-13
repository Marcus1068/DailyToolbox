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
            //print(conv.decimalToRoman)
            
            
        }
        else{
            romanTextField.text = ""
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
