/*

Copyright 2020-2026 Marcus Deuß

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

// MARK: - Bundle info helpers

extension Bundle {
    var appVersion: String { (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "" }
    var appBuild:   String { (object(forInfoDictionaryKey: "CFBundleVersion")            as? String) ?? "" }
    var appName:    String { (object(forInfoDictionaryKey: "CFBundleName")               as? String) ?? "" }
}

// MARK: - Digit decomposition

extension BinaryInteger {
    var digits: [Int] {
        String(describing: self).compactMap { Int(String($0)) }
    }
}

// MARK: - Array deduplication

extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        reduce(into: []) { result, element in
            if !result.contains(element) { result.append(element) }
        }
    }
}

// MARK: - Date formatting

extension Date {
    func toMediumDateString() -> String {
        formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Locale helpers

public struct Local {
    static let locale         = Locale.current
    static let isMetric       = locale.measurementSystem == .metric
    static let currencyCode   = locale.currency?.identifier
    static let currencySymbol = locale.currencySymbol
    static let languageCode   = locale.language.languageCode?.identifier

    static func currentLocaleForDate() -> String { languageCode ?? "en" }
}

// MARK: - System Settings URL

/// Opens the correct system settings page on both iOS and Mac Catalyst.
/// iOS: app-specific Settings page.
/// Mac Catalyst: System Settings → Privacy & Security (camera or location).
@MainActor
func openSystemSettings(privacy: String? = nil) {
    #if targetEnvironment(macCatalyst)
    let base = "x-apple.systempreferences:com.apple.preference.security"
    let urlStr = privacy.map { "\(base)?\($0)" } ?? base
    #else
    let urlStr = UIApplication.openSettingsURLString
    #endif
    guard let url = URL(string: urlStr) else { return }
    Task { @MainActor in await UIApplication.shared.open(url) }
}
