//
//  HorizonViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 24.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit
import CoreLocation

class HorizonViewController: UIViewController {

    private let locationManager = CLLocationManager()
    @IBOutlet weak var altitudeStringLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    
    // computed properties
    var altitude: Double = 0.0{
        didSet{
            self.altitudeLabel.text = String(format: "My altitude is %.2f m", altitude)
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

extension HorizonViewController: CLLocationManagerDelegate {
    
    // update location when changes occur
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            altitude = lastLocation.altitude
            //altitudeLabel.text = String(format: "My altitude is %.2f m", altitude)
        }
    }
}
