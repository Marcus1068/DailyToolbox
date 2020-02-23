//
//  TranslationViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 23.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit
import WebKit

class TranslationViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = "Translation"
        
        let url = URL(string: "https://dict.leo.org/dict/mobile.php")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
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
