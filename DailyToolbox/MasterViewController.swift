//
//  MasterViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 14.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UISplitViewControllerDelegate {

    var detailViewController: PercentageViewController? = nil

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

        }
        
        // removes extra separator lines after last table entry
        self.tableView.tableFooterView = UIView()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        //clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPercentage" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! PercentageViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
        
        if segue.identifier == "showTemp" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! TemperatureViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showTranslation" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! TranslationViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showDecimal" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! ConvertNumbersViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showHorizon" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! HorizonViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showBenchmark" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! BenchmarkViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
        
        if segue.identifier == "showCurrency" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! CurrencyConverterViewController
                //controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                //detailViewController = controller
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9 //objects.count
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

}

