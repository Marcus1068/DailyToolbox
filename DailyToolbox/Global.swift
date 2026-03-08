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
//  Global.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 23.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//


import Foundation

enum Global {
    // App store link
    static let AppLink = "https://itunes.apple.com/de/app/inventory-app/id1386694734?l=de&ls=1&mt=8"
    
    // name of the app in about view
    static let emailAdr = "mdeuss+dailytoolbox@gmail.com"
    static let website = "https://marcus-deuss.de/?page_id=201"
    static let privacy = "https://marcus-deuss.de/?page_id=203"
    
    // localization strings
    static let all = "All"
    
    static let ok = "OK"
    static let cancel = "Cancel"
    static let delete = "Delete"
    static let confirm = "Confirm"
    static let dismiss = "Dismiss"
    static let error = "Error"
    static let done = "Done"
    static let none = "None"
    static let duplicate = "Duplicate"
    static let edit = "Edit"
    static let copy = "Copy"
    static let save = "Save"
    static let back = "Back"
    
    static let appSettings = "App Settings"
    static let appInformation = "Information"
    static let appFeedback = "Feedback"
    static let appManual = "Manual"
    static let appPrivacy = "Privacy"
    
    static let emailNotSent = "Email could not be sent"
    static let emailDevice = "Your device could not send email"
    static let emailConfig = "Please check your email configuration"
    static let support = "Support"
    
    static let numberWrongMessage = "Please enter correct number"
    static let numberWrongTitle = "Number invalid"
    
    static let keyEyeLevel = "eyeLevel"
    static let keyCostWatt = "costWatt"
    
    
}

/// Increments the launch counter and requests an App Store review after 4 launches.
@MainActor
func appstoreReview() {
    var count = UserDefaults.standard.integer(forKey: UserDefaultKeys.processCompletedCountKey)
    count += 1
    UserDefaults.standard.set(count, forKey: UserDefaultKeys.processCompletedCountKey)

    let infoDictionaryKey = kCFBundleVersionKey as String
    guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
        else { return }

    let lastVersionPrompted = UserDefaults.standard.string(forKey: UserDefaultKeys.lastVersionPromptedForReviewKey)

    if count >= 4 && currentVersion != lastVersionPrompted {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            // SKStoreReviewController.requestReview() — re-enable when using StoreKit
            UserDefaults.standard.set(currentVersion, forKey: UserDefaultKeys.lastVersionPromptedForReviewKey)
        }
    }
}
