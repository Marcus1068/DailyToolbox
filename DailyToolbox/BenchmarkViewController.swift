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

class BenchmarkViewController: UIViewController {

    @IBOutlet weak var arcSegment: UISegmentedControl!
    @IBOutlet weak var swiftSegment: UISegmentedControl!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var osVersionLabel: UILabel!
    
    var arcNumber: Int = 10000
    
    var swiftNumber: Int = 10000
    
    func configureView() {
        self.title = "Benchmark device"
        
        resultLabel.text = "0.0 seconds"
        
        deviceLabel.text = DeviceInfo.getDeviceName()
        osVersionLabel.text = DeviceInfo.getOSVersion()
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
    
    @IBAction func stringConcatButton(_ sender: UIButton) {
        let test = Benchmark.benchmarkString()
        
        resultLabel.text = String(format: "%.4f", test) + " seconds"
    }
    
    @IBAction func randomArcButton(_ sender: UIButton) {
        let test = Benchmark.benchmarkRandomNumbersArc4(range: arcNumber)
        
        resultLabel.text = String(format: "%.4f", test) + " seconds"
    }
    
    @IBAction func randomSwiftButton(_ sender: UIButton) {
        let test = Benchmark.benchmarkRandomNumbersSwift(range: swiftNumber)
        
        resultLabel.text = String(format: "%.4f", test) + " seconds"
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
