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
//  DeviceInfo.swift
//
//  Created by Marcus Deuß on 17.04.18.
//  Copyright © 2018 Marcus Deuß. All rights reserved.
//

import Foundation

enum DeviceInfo {

    /// Current OS version string, e.g. "18.3.1"
    static func getOSVersion() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    /// User-visible device name derived from the Bonjour hostname.
    /// ProcessInfo.hostName typically returns "Marcuss-iPhone.local";
    /// stripping the ".local" suffix gives a clean display name.
    static func getDeviceName() -> String {
        let host = ProcessInfo.processInfo.hostName
        if host.hasSuffix(".local") {
            return String(host.dropLast(".local".count))
        }
        return host
    }
}
