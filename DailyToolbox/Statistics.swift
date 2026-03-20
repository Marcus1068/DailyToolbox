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
//  Statistics.swift
//  DailyToolbox
//

import Foundation

struct Statistics {
    let values: [Double]

    var count: Int { values.count }
    var sum: Double { values.reduce(0, +) }
    var minimum: Double? { values.min() }
    var maximum: Double? { values.max() }

    var mean: Double? {
        guard count > 0 else { return nil }
        return sum / Double(count)
    }

    var median: Double? {
        guard count > 0 else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[mid - 1] + sorted[mid]) / 2.0
            : sorted[mid]
    }

    /// Returns all modes. Empty when every value is unique.
    var modes: [Double] {
        guard count > 1 else { return [] }
        var freq: [Double: Int] = [:]
        for v in values { freq[v, default: 0] += 1 }
        let maxFreq = freq.values.max() ?? 0
        guard maxFreq > 1 else { return [] }
        return freq.filter { $0.value == maxFreq }.keys.sorted()
    }

    var range: Double? {
        guard let lo = minimum, let hi = maximum else { return nil }
        return hi - lo
    }

    /// Population variance (divides by N).
    var variance: Double? {
        guard count > 1, let m = mean else { return nil }
        return values.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(count)
    }

    /// Population standard deviation.
    var standardDeviation: Double? {
        guard let v = variance else { return nil }
        return sqrt(v)
    }
}
