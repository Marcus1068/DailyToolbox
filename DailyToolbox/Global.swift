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

class Global{
    // App store link
    static let AppLink = "https://itunes.apple.com/de/app/inventory-app/id1386694734?l=de&ls=1&mt=8"
    
    // name of the app in about view
    static let emailAdr = "mdeuss+dailytoolbox@gmail.com"
    static let website = "https://marcus-deuss.de/?page_id=201"
    static let privacy = "https://marcus-deuss.de/?page_id=203"
    
    // localization strings
    static let all = NSLocalizedString("All", comment: "All")
    
    static let ok = NSLocalizedString("OK", comment: "OK")
    static let cancel = NSLocalizedString("Cancel", comment: "Cancel")
    static let delete = NSLocalizedString("Delete", comment: "Delete")
    static let confirm = NSLocalizedString("Confirm", comment: "Confirm")
    static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss")
    static let error = NSLocalizedString("Error", comment: "Error")
    static let done = NSLocalizedString("Done", comment: "Done")
    static let none = NSLocalizedString("None", comment: "None")
    static let duplicate = NSLocalizedString("Duplicate", comment: "Duplicate")
    static let edit = NSLocalizedString("Edit", comment: "Edit")
    static let copy = NSLocalizedString("Copy", comment: "Copy")
    static let save = NSLocalizedString("Save", comment: "Save")
    static let back = NSLocalizedString("Back", comment: "Back")
    
    static let appSettings = NSLocalizedString("App Settings", comment: "App Settings")
    static let appInformation = NSLocalizedString("Information", comment: "Information")
    static let appFeedback = NSLocalizedString("Feedback", comment: "Feedback")
    static let appManual = NSLocalizedString("Manual", comment: "Manual")
    static let appPrivacy = NSLocalizedString("Privacy", comment: "Privacy")
    
    static let emailNotSent = NSLocalizedString("Email could not be sent", comment: "Email could not be sent")
    static let emailDevice = NSLocalizedString("Your device could not send email", comment: "Your device could not send email")
    static let emailConfig = NSLocalizedString("Please check your email configuration", comment: "Please check your email configuration")
    static let support = NSLocalizedString("Support", comment: "Support")
}
