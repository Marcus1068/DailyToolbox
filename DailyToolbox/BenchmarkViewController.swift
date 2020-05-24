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
//  BenchmarkViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 27.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class BenchmarkViewController: UIViewController, UIPointerInteractionDelegate {

    @IBOutlet weak var arcSegment: UISegmentedControl!
    @IBOutlet weak var swiftSegment: UISegmentedControl!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var osVersionLabel: UILabel!
    @IBOutlet weak var randomArcButton: UIButton!
    @IBOutlet weak var randomSwiftButton: UIButton!
    @IBOutlet weak var stringsButton: UIButton!
    
    var arcNumber: Int = 10000
    
    var swiftNumber: Int = 10000
    
    func configureView() {
        self.title = NSLocalizedString("Benchmark tool", comment: "Benchmark tool")
        
        resultLabel.text = "0.0 " + NSLocalizedString("seconds", comment: "seconds")
        
        deviceLabel.text = DeviceInfo.getDeviceName()
        osVersionLabel.text = DeviceInfo.getOSVersion()
        
        hideKeyboardWhenTappedAround()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: randomArcButton, pointerInteractionDelegate: self)
            customPointerInteraction(on: randomSwiftButton, pointerInteractionDelegate: self)
            customPointerInteraction(on: stringsButton, pointerInteractionDelegate: self)
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
    }
    
    // UI controls
    
    @IBAction func arcSegmentControl(_ sender: UISegmentedControl) {
        arcNumber = Int(arcSegment.titleForSegment(at: arcSegment.selectedSegmentIndex)!)!
    }
    
    @IBAction func swiftSegmentControl(_ sender: UISegmentedControl) {
        swiftNumber = Int(swiftSegment.titleForSegment(at: swiftSegment.selectedSegmentIndex)!)!
    }
    
    @IBAction func stringConcatAction(_ sender: UIButton) {
        // add the spinner view controller
        let child = SpinnerViewController()
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        DispatchQueue.main.async() {
            // here comes long running function
            let test = Benchmark.benchmarkString()
            
            self.resultLabel.text = String(format: "%.4f", test) + " " + NSLocalizedString("seconds", comment: "Seconds")
            
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    @IBAction func randomArcAction(_ sender: UIButton) {
        // add the spinner view controller
        let child = SpinnerViewController()
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        DispatchQueue.main.async() {
            // here comes long running function
            let test = Benchmark.benchmarkRandomNumbersArc4(range: self.arcNumber)
            
            self.resultLabel.text = String(format: "%.4f", test) + " " + NSLocalizedString("seconds", comment: "Seconds")
            
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    @IBAction func randomSwiftAction(_ sender: UIButton) {
        // add the spinner view controller
        let child = SpinnerViewController()
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        DispatchQueue.main.async() {
            // here comes long running function
            let test = Benchmark.benchmarkRandomNumbersSwift(range: self.swiftNumber)
            
            self.resultLabel.text = String(format: "%.4f", test) + " " + NSLocalizedString("seconds", comment: "Seconds")
            
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
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
