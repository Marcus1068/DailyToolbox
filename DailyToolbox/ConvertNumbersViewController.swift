//
//  ComputeNumbersViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class ConvertNumbersViewController: UIViewController {

    @IBOutlet weak var decimalTextField: UITextField!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = "Convert Numbers"
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
    
    @IBAction func convertButton(_ sender: UIButton) {
        let inp = self.decimalTextField.text
        let input : Int = Int(inp!)!
        let num = Zahlen(dezimal: input)
        self.resultLabel.text = num.hexadezimal
    }
    
}
