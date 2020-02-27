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
    
    var arcNumber: Int = 1000
    
    var swiftNumber: Int = 1000
    
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
