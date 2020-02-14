//
//  TemperatureViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit
import WebKit

class TemperatureViewController: UIViewController{
  
    @IBOutlet weak var webView: WKWebView!
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = "Temperature Calculation"
        
        let url = URL(string: "https://dict.leo.org/dict/mobile.php")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }
}
