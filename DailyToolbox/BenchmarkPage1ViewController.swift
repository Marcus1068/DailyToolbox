//
//  BenchmarkPage1ViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 25.05.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class BenchmarkPage1ViewController: UIViewController, UIPointerInteractionDelegate {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var randomArcButton: UIButton!
    @IBOutlet weak var randomSwiftButton: UIButton!
    @IBOutlet weak var additionButton: UIButton!
    @IBOutlet weak var arcSegment: UISegmentedControl!
    @IBOutlet weak var swiftSegment: UISegmentedControl!
    @IBOutlet weak var additionSegment: UISegmentedControl!
    @IBOutlet weak var repeatStepper: UIStepper!
    @IBOutlet weak var repeatLabel: UILabel!
    
    var arcNumber: Int = 50000
    var swiftNumber: Int = 50000
    var additionNumber: Int = 50000
    
    func configureView() {
        self.title = NSLocalizedString("Benchmark tool", comment: "Benchmark tool")
        
        resultLabel.text = "0.0 " + NSLocalizedString("seconds", comment: "seconds")
        
        hideKeyboardWhenTappedAround()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: randomArcButton, pointerInteractionDelegate: self)
            customPointerInteraction(on: randomSwiftButton, pointerInteractionDelegate: self)
            customPointerInteraction(on: additionButton, pointerInteractionDelegate: self)
            
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
    
    @IBAction func repeatStepperAction(_ sender: UIStepper) {
        repeatLabel.text = Int(sender.value).description
    }
    @IBAction func arcSegmentControl(_ sender: UISegmentedControl) {
        arcNumber = Int(arcSegment.titleForSegment(at: arcSegment.selectedSegmentIndex)!)!
    }
    
    @IBAction func swiftSegmentControl(_ sender: UISegmentedControl) {
        swiftNumber = Int(swiftSegment.titleForSegment(at: swiftSegment.selectedSegmentIndex)!)!
    }
    
    @IBAction func additionSegmentControl(_ sender: UISegmentedControl) {
        additionNumber = Int(additionSegment.titleForSegment(at: additionSegment.selectedSegmentIndex)!)!
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
    
    @IBAction func additionAction(_ sender: UIButton) {
        // add the spinner view controller
        let child = SpinnerViewController()
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        DispatchQueue.main.async() {
            // here comes long running function
            
            let test = Benchmark.benchmarkAddition(range: self.additionNumber)
            
            self.resultLabel.text = String(format: "%.4f", test) + " " + NSLocalizedString("seconds", comment: "Seconds")
            
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    
}
