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
//  HorizonViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 24.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit
import CoreLocation

class HorizonViewController: UIViewController, UITextFieldDelegate {

    private let locationManager = CLLocationManager()
    @IBOutlet weak var altitudeStringLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var eyeLevelTextField: UITextField!
    @IBOutlet weak var distanceResultLabel: UILabel!
    @IBOutlet weak var eyeLevelLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var formulaTextView: UITextView!
    
    
    // computed properties
    
    var horizonDistance: String = "0.0 km"{
        didSet{
            self.distanceResultLabel.text = horizonDistance
        }
    }
    
    var altitude: Double = 0.0{
        didSet{
            self.altitudeLabel.text = String(format: "%.2f m", altitude)
            let dist = ComputeHorizon(eyeLevel: eyeLevel, altitude: altitude)
            horizonDistance = dist.viewDistanceToString
        }
        
    }
    
    // properties
    var eyeLevel: Double = 0.0
    
    
    // initial configuration works
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = NSLocalizedString("Horizon calculation", comment: "Horizon calculation")
        altitudeStringLabel.text = NSLocalizedString("Altitude", comment: "Altitude")
        eyeLevelLabel.text = NSLocalizedString("Eye Level", comment: "Eye Level")
        distanceResultLabel.text = NSLocalizedString("Horizon distance", comment: "Horizon distance")
        infoLabel.text = NSLocalizedString("Calculates distance of horizon by meassuring height with GPS sensor", comment: "Calculates Info")
        
        formulaTextView.text = NSLocalizedString("Formula for computing the horizon distance: 3.57 * sqrt(Altitude + Eye Level) = distance", comment: "Formula")
        
        /*  Request a user’s authorization to use his location.
            Ask our manager to report every movement of the user.
            Ask our manager for the best accuracy.
            Start to update location.
            Set manager’s delegate to our view controller. */
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        eyeLevelTextField.becomeFirstResponder()
        
        eyeLevelTextField.delegate = self
        
        eyeLevelTextField.addTarget(self, action: #selector(HorizonViewController.eyeLevelTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        if eyeLevelTextField.text!.count > 0{
            let input : Double = Double(eyeLevelTextField.text!)!
            let dist = ComputeHorizon(eyeLevel: input, altitude: altitude)
            horizonDistance = dist.viewDistanceToString
        }
        
        hideKeyboardWhenTappedAround()
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
    
    @objc func eyeLevelTextFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text!.replacingOccurrences(of: ",", with: ".")
        
        guard Double(textField.text!) != nil else {
            if textField.text!.count > 0 {
                displayAlert(title: Global.numberWrongTitle, message: Global.numberWrongMessage, buttonText: Global.ok)
            }
            return
        }
        
        if textField.text!.count > 0{
            let input : Double = Double(textField.text!)!
            let dist = ComputeHorizon(eyeLevel: input, altitude: altitude)
            horizonDistance = dist.viewDistanceToString
        }
        else{
            let dist = ComputeHorizon(eyeLevel: 0.0, altitude: altitude)
            horizonDistance = dist.viewDistanceToString
        }
    }
    
    // check for valid keyboard input characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn:"0123456789.,").inverted
            
        let components = string.components(separatedBy: allowedCharacters)
        let filtered = components.joined(separator: "")
        
        if string == filtered {
            return true
        } else {
            return false
        }
    }

}

extension HorizonViewController: CLLocationManagerDelegate {
    
    // update location when changes occur
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            altitude = lastLocation.altitude
            //altitudeLabel.text = String(format: "My altitude is %.2f m", altitude)
        }
    }
}
