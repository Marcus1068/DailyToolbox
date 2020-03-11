//
//  DetailViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class PercentageViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var percentTextField: UITextField!
    @IBOutlet weak var percentValueTextField: UITextField!
    @IBOutlet weak var baseValueTextField: UITextField!
    
    func configureView() {
        
        //detailItem = true
        self.title = "Percentage Calculation"
        
        percentTextField.becomeFirstResponder()
        
        percentTextField.delegate = self
        percentValueTextField.delegate = self
        baseValueTextField.delegate = self
        
        percentTextField.addTarget(self, action: #selector(PercentageViewController.percentTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        percentValueTextField.addTarget(self, action: #selector(PercentageViewController.percentValueTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        baseValueTextField.addTarget(self, action: #selector(PercentageViewController.baseValueTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }
    
    @objc func percentTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            /*let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            percentValueTextField.text = num.hexadecimal.uppercased()
            baseValueTextField.text = num.binary */
        }
        else{
            percentValueTextField.text = ""
            baseValueTextField.text = ""
        }
    }
    
    @objc func percentValueTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            /*let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            percentValueTextField.text = num.hexadecimal.uppercased()
            baseValueTextField.text = num.binary */
        }
        else{
            percentValueTextField.text = ""
            baseValueTextField.text = ""
        }
    }

    @objc func baseValueTextFieldDidChange(_ textField: UITextField) {
        if textField.text!.count > 0{
            /*let input : Int = Int(textField.text!)!
            let num = ConvertNumbers(decimal: input)
            percentValueTextField.text = num.hexadecimal.uppercased()
            baseValueTextField.text = num.binary */
        }
        else{
            percentValueTextField.text = ""
            baseValueTextField.text = ""
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == percentTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == percentValueTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        if textField == baseValueTextField{
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

    @IBAction func calculateButton(_ sender: UIButton) {
        
        if percentTextField.text!.count > 0 && percentValueTextField.text!.count > 0 {
            let p : Double = Double(percentValueTextField.text!)!
            let v : Double = Double(percentTextField.text!)!
            let str = Percent(prozentwert: p, prozentsatz: v)
            baseValueTextField.text = str.grundWertToString
        }
        
        if baseValueTextField.text!.count > 0 && percentValueTextField.text!.count > 0 {
            let p : Double = Double(percentValueTextField.text!)!
            let g : Double = Double(baseValueTextField.text!)!
            let str = Percent(prozentwert: p, grundwert: g)
            percentTextField.text = str.prozentSatzToString
        }
        
        if baseValueTextField.text!.count > 0 && percentTextField.text!.count > 0 {
            let p : Double = Double(percentTextField.text!)!
            let g : Double = Double(baseValueTextField.text!)!
            let str = Percent(prozentsatz: p, grundwert: g)
            percentValueTextField.text = str.prozentWertToString
        }
    }
    
}

