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
//  MyExtensions.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 21.03.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation
import UIKit

// MARK: extensions
// all generel extensions that migth be usefull in apps

// get app version number from Xcode version number
extension UIApplication {
    // xcode version string
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    // xcode build number
    static var appBuild: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
    
    // xcode app name
    static var appName: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

extension UIViewController {
    
    // hide keyboard when tapping somewhere on the view
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // general alert extension with just one button to be pressed
    func displayAlert(title: String, message: String, buttonText: String) {
        
        // Create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        // Add an action
        alert.addAction(UIAlertAction(title: buttonText, style: .default, handler: { action in
            
            // Dismiss when the button is pressed
            self.dismiss(animated: true, completion: nil)
            
        }))
        
        // Add it to viewController
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController{
    // MARK: - UIPointerInteractionDelegate
    @available(iOS 13.4, *)
    func customPointerInteraction(on view: UIView, pointerInteractionDelegate: UIPointerInteractionDelegate) {
        let pointerInteraction = UIPointerInteraction(delegate: pointerInteractionDelegate)
        view.addInteraction(pointerInteraction)
    }

     
  /*
     // hover effect
     @objc(pointerInteraction:styleForRegion:) @available(iOS 13.4, *)
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle? = nil

        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: UIPointerEffect.hover(targetedPreview, preferredTintMode: .overlay, prefersShadow: true, prefersScaledContent: true))
        }
        return pointerStyle
    } */
    
    // lift effect
    @objc(pointerInteraction:styleForRegion:) @available(iOS 13.4, *)
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle? = nil

        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: UIPointerEffect.lift(targetedPreview))
        }
        return pointerStyle
    }
    
/*
    // crosshair custom cursor made with bezier curves
    @objc(pointerInteraction:styleForRegion:) @available(iOS 13.4, *)
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        let shape = UIBezierPath()
        shape.move(to: CGPoint(x: 10, y: 6))
        shape.addLine(to: CGPoint(x: 10, y: 0))
        shape.addLine(to: CGPoint(x: 6, y: 0))
        shape.addLine(to: CGPoint(x: 6, y: 6))
        shape.addLine(to: CGPoint(x: 0, y: 6))
        shape.addLine(to: CGPoint(x: 0, y: 10))
        shape.addLine(to: CGPoint(x: 6, y: 10))
        shape.addLine(to: CGPoint(x: 6, y: 16))
        shape.addLine(to: CGPoint(x: 10, y: 16))
        shape.addLine(to: CGPoint(x: 10, y: 10))
        shape.addLine(to: CGPoint(x: 16, y: 10))
        shape.addLine(to: CGPoint(x: 16, y: 6))
        shape.addLine(to: CGPoint(x: 10, y: 6))
        shape.close()
        let pointerShape = UIPointerShape.path(shape)
        
        return UIPointerStyle(shape: pointerShape)
    } */
}

// deconstruct decimal number as array of digits
extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { Int(String($0)) }
    }
}


// remove dulicates from an array
extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        return reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}


// to get string from a date
// usage: yourString = yourDate.toString(withFormat: "yyyy")
extension Date {
    func toString(withFormat format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        let myString = formatter.string(from: self)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format
        
        return formatter.string(from: yourDate!)
    }
}


// used for general localization
public struct Local{
    //User region setting return
    static let locale = Locale.current
    
    //Returns true if the locale uses the metric system (Note: Only three countries do not use the metric system: the US, Liberia and Myanmar.)
    static let isMetric = locale.usesMetricSystem
    
    //Returns the currency code of the locale. For example, for “zh-Hant-HK”, returns “HKD”.
    static let currencyCode  = locale.currencyCode
    
    //Returns the currency symbol of the locale. For example, for “zh-Hant-HK”, returns “HK$”.
    static let currencySymbol = locale.currencySymbol
    
    static let languageCode = locale.languageCode
    
    static func currentLocaleForDate() -> String{
        return Local.languageCode!
        
    }
}
