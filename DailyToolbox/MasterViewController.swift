/*

Copyright 2021 Marcus Deuß

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
//  MasterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UISplitViewControllerDelegate, UIPointerInteractionDelegate {
    
    @IBOutlet weak var staticCellPercentage: UITableViewCell!
    @IBOutlet weak var staticCellCurrency: UITableViewCell!
    @IBOutlet weak var staticCellConvertNumbers: UITableViewCell!
    @IBOutlet weak var staticCellInterestRate: UITableViewCell!
    @IBOutlet weak var staticCellTemperature: UITableViewCell!
    @IBOutlet weak var staticCellCalendar: UITableViewCell!
    @IBOutlet weak var staticCellHorizon: UITableViewCell!
    @IBOutlet weak var staticCellTranslation: UITableViewCell!
    @IBOutlet weak var staticCellBenchmark: UITableViewCell!
    @IBOutlet weak var staticCellRomanNumbers: UITableViewCell!
    @IBOutlet weak var staticCellPower: UITableViewCell!
    @IBOutlet weak var staticCellAbout: UITableViewCell!
    
    var detailViewController: PercentageViewController? = nil

    // number of static table cells in each section, must be changed when new section or cell will be added
    var sectionInfo  = [7, 4, 2]
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let split = splitViewController {
            let controllers = split.viewControllers
            // set default view controller to appear on screen
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? PercentageViewController
            
            //split.delegate = self
            //split.preferredDisplayMode = .allVisible
            //split.preferredDisplayMode = .primaryOverlay;
            split.primaryBackgroundStyle = .sidebar
        }
        
        // removes extra separator lines after last table entry
        self.tableView.tableFooterView = UIView()
        
        // pointer interaction
        if #available(iOS 13.4, *) {
            customPointerInteraction(on: staticCellPercentage, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellCurrency, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellConvertNumbers, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellInterestRate, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellTemperature, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellCalendar, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellHorizon, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellTranslation, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellBenchmark, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellRomanNumbers, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellPower, pointerInteractionDelegate: self)
            customPointerInteraction(on: staticCellAbout, pointerInteractionDelegate: self)
        } else {
            // Fallback on earlier versions
        }
        
        // macCatalyst: hover action
        #if targetEnvironment(macCatalyst)
        let hoverPercentage = UIHoverGestureRecognizer(target: self, action: #selector(hoveringPercentage(_:)))
        staticCellPercentage.addGestureRecognizer(hoverPercentage)
        
        let hoverCurrency = UIHoverGestureRecognizer(target: self, action: #selector(hoveringCurrency(_:)))
        staticCellCurrency.addGestureRecognizer(hoverCurrency)
        
        let hoverConvertNumbers = UIHoverGestureRecognizer(target: self, action: #selector(hoveringConvertNumbers(_:)))
        staticCellConvertNumbers.addGestureRecognizer(hoverConvertNumbers)
        
        let hoverInterestRate = UIHoverGestureRecognizer(target: self, action: #selector(hoveringInterestRate(_:)))
        staticCellInterestRate.addGestureRecognizer(hoverInterestRate)
        
        let hoverTemperature = UIHoverGestureRecognizer(target: self, action: #selector(hoveringTemperature(_:)))
        staticCellTemperature.addGestureRecognizer(hoverTemperature)
        
        let hoverCalendar = UIHoverGestureRecognizer(target: self, action: #selector(hoveringCalendar(_:)))
        staticCellCalendar.addGestureRecognizer(hoverCalendar)
        
        let hoverHorizon = UIHoverGestureRecognizer(target: self, action: #selector(hoveringHorizon(_:)))
        staticCellHorizon.addGestureRecognizer(hoverHorizon)
        
        let hoverTranslation = UIHoverGestureRecognizer(target: self, action: #selector(hoveringTranslation(_:)))
        staticCellTranslation.addGestureRecognizer(hoverTranslation)
        
        let hoverBenchmark = UIHoverGestureRecognizer(target: self, action: #selector(hoveringBenchmark(_:)))
        staticCellBenchmark.addGestureRecognizer(hoverBenchmark)
        
        let hoverRomanNumbers = UIHoverGestureRecognizer(target: self, action: #selector(hoveringRomanNumbers(_:)))
        staticCellRomanNumbers.addGestureRecognizer(hoverRomanNumbers)
        
        let hoverPower = UIHoverGestureRecognizer(target: self, action: #selector(hoveringPower(_:)))
        staticCellPower.addGestureRecognizer(hoverPower)
        
        let hoverAbout = UIHoverGestureRecognizer(target: self, action: #selector(hoveringAbout(_:)))
        staticCellAbout.addGestureRecognizer(hoverAbout)
        
        #endif
        
        // enable store reviews
        appstoreReview()
    }

    override func viewWillAppear(_ animated: Bool) {
        //clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // macCatalyst: hover action
    #if targetEnvironment(macCatalyst)
    @objc func hoveringPercentage(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellPercentage.backgroundColor = .systemBlue
        case .ended:
            staticCellPercentage.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringCurrency(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellCurrency.backgroundColor = .systemBlue
        case .ended:
            staticCellCurrency.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringConvertNumbers(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellConvertNumbers.backgroundColor = .systemBlue
        case .ended:
            staticCellConvertNumbers.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringInterestRate(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellInterestRate.backgroundColor = .systemBlue
        case .ended:
            staticCellInterestRate.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringTemperature(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellTemperature.backgroundColor = .systemBlue
        case .ended:
            staticCellTemperature.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringCalendar(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellCalendar.backgroundColor = .systemBlue
        case .ended:
            staticCellCalendar.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringHorizon(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellHorizon.backgroundColor = .systemBlue
        case .ended:
            staticCellHorizon.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringTranslation(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellTranslation.backgroundColor = .systemBlue
        case .ended:
            staticCellTranslation.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringBenchmark(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellBenchmark.backgroundColor = .systemBlue
        case .ended:
            staticCellBenchmark.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringRomanNumbers(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellRomanNumbers.backgroundColor = .systemBlue
        case .ended:
            staticCellRomanNumbers.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringPower(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellPower.backgroundColor = .systemBlue
        case .ended:
            staticCellPower.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    @objc func hoveringAbout(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            staticCellAbout.backgroundColor = .systemBlue
        case .ended:
            staticCellAbout.backgroundColor = .systemBackground
        default:
            break
        }
    }
    
    #endif
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //let controller = (segue.destination as! UINavigationController).topViewController
        
        /*
        switch(segue.identifier){
        case "showPercentage":
            let controller = (segue.destination as! UINavigationController).topViewController as! PercentageViewController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            detailViewController = controller
        case "showTemp":
            let controller = (segue.destination as! UINavigationController).topViewController as! TemperatureViewController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            detailViewController = controller
        case "showTranslation":
            controller = (segue.destination as! UINavigationController).topViewController as! TranslationViewController
        case "showDecimal":
            controller = (segue.destination as! UINavigationController).topViewController as! ConvertNumbersViewController
        case "showHorizon":
            controller = (segue.destination as! UINavigationController).topViewController as! HorizonViewController
        case "showBenchmark":
            controller = (segue.destination as! UINavigationController).topViewController as! BenchmarkViewController
        case "showCurrency":
            controller = (segue.destination as! UINavigationController).topViewController as! CurrencyConverterViewController
        case "showInterestRate":
            controller = (segue.destination as! UINavigationController).topViewController as! InterestRateViewController
        default:
            print("not allowed")
        }
        
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
        detailViewController = controller */
        

        if segue.identifier == "showPercentage" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! PercentageViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
        
        if segue.identifier == "showTemp" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! TemperatureViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showTranslation" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! TranslationViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showDecimal" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! ConvertNumbersViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showHorizon" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! HorizonViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showBenchmark" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! BenchmarkViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showCurrency" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! CurrencyConverterViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showInterestRate" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! InterestRateViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showCalendar" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! CalendarCalculationViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showRoman" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DecimalRomanNumbersViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showPower" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! PowerConsumptionViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showAbout" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! AboutViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showBenchmarkPageView" {
            if let _ = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! BenchmarkPageViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionInfo.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionInfo[section] //objects.count 12
    }

 /*   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let object = objects[indexPath.row] as! NSDate
        cell.textLabel!.text = object.description
        return cell
    }
*/
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    @IBAction func aboutInfoAction(_ sender: UIBarButtonItem) {
        let version = UIApplication.appVersion!
        let build = UIApplication.appBuild!
        let appName = UIApplication.appName!
        
        displayAlert(title: "\(appName) - ver. \(version) (\(build))", message: "(c) 2020 by Marcus Deuß", buttonText: NSLocalizedString("Dismiss", comment: "Dismiss"))
    }
}

