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
    
    
    // computed properties
    
    var horizonDistance: String = "0.0 km"{
        didSet{
            self.distanceResultLabel.text = horizonDistance
        }
    }
    
    var eyeLevel: Double = 0.0
    
    var altitude: Double = 0.0{
        didSet{
            self.altitudeLabel.text = String(format: "My altitude is %.2f m", altitude)
            let dist = ComputeHorizon(eyeLevel: eyeLevel, altitude: altitude)
            horizonDistance = dist.viewDistanceToString
        }
        
    }
    
    
    func configureView() {
        // Update the user interface for the detail item.
        
        self.title = "Horizon calculation"
        
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
        if textField == eyeLevelTextField{
            switch(string){
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                return true
            
            case "":
                return true
                
            default:
                    return false
            }
        }
        
        return true
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
