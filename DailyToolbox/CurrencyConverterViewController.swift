//
//  CurrencyConverterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 04.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class CurrencyConverterViewController: UIViewController {
    
    func configureView() {
        
        self.title = "Currency Converter"
        
        let cvt = CurrencyConverter()
        if let dollar = cvt.getUSDCurrency(){
            print(dollar)
        }
        
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