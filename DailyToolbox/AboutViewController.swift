/*

Copyright 2020 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  AboutViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 23.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate, UIPointerInteractionDelegate {
    @IBOutlet weak var feedbackOutlet: UIButton!
    @IBOutlet weak var informationOutlet: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var privacyOutlet: UIButton!
    @IBOutlet weak var osVersionLabel: UILabel!
    
    func configureView(){
        
        versionLabel.text = NSLocalizedString("Version", comment: "Version") + ": " + UIApplication.appVersion! + " (" + UIApplication.appBuild! + ")"
        
        osVersionLabel.text = NSLocalizedString("Running on", comment: "Running on") + " " + DeviceInfo.getOSName() + " " + DeviceInfo.getOSVersion()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: feedbackOutlet, pointerInteractionDelegate: self)
            customPointerInteraction(on: informationOutlet, pointerInteractionDelegate: self)
            customPointerInteraction(on: privacyOutlet, pointerInteractionDelegate: self)
        } else {
            // Fallback on earlier versions
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

    /*
    // MARK: - Email delegate
    */
    
    /// Prepares mail sending controller
    ///
    /// **Extremely** important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    /// - Returns: mailComposerVC
    func configuredMailComposeViewController() -> MFMailComposeViewController
    {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients([Global.emailAdr])
        mailComposerVC.setSubject(UIApplication.appName! + " " + (UIApplication.appVersion!) + " " + Global.support)
        let msg = NSLocalizedString("I have some suggestions: ", comment: "I have some suggestions: ")
        mailComposerVC.setMessageBody(msg, isHTML: false)
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: actions
    
    
    @IBAction func privacyAction(_ sender: UIButton) {
        // hide keyboard
        self.view.endEditing(true)
        
        // open safari browser for more information, source code etc.
        if let url = URL(string: Global.privacy) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func informationButton(_ sender: UIButton) {
        // hide keyboard
        self.view.endEditing(true)
        
        // open safari browser for more information, source code etc.
        if let url = URL(string: Global.website) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func feedbackAction(_ sender: UIButton) {
       
        // hide keyboard
        self.view.endEditing(true)
        
        let mailComposeViewController = configuredMailComposeViewController()
        
        if MFMailComposeViewController.canSendMail()
        {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
        else
        {
            displayAlert(title: Global.emailNotSent, message: Global.emailDevice, buttonText: Global.emailConfig)
        }
        
    }
    
}
