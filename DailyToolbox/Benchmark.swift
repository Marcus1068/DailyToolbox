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
//  Benchmark.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 27.02.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import Foundation

class Benchmark{
    
    // functions
    
    // calculate benchmark and return in seconds passed since start, based on Swift random
    static func benchmarkRandomNumbersSwift(range: Int) -> Float{
        let start = Date()
        
        var sum = 0
        for _ in 1...range{
            // swift regular random method takes about 5 times longer than arc4random
            sum += Int.random(in: 0 ..< 100)
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        
        return Float(seconds)
    }
    
    // calculate benchmark and return in seconds passed since start, based on C arc4random method
    static func benchmarkRandomNumbersArc4(range: Int) -> Float{
        let start = Date()
        
        var sum = 0
        for _ in 1...range{
            // swift regular random method takes about 5 times longer than arc4random
            // sum += Int.random(in: 0 ..< 100)
            sum += Int(arc4random_uniform(100))
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        
        return Float(seconds)
    }
    
    static func benchmarkString() -> Float{
        let start = Date()
        
        var s: String = "Benchmark test with Swift 5"
        
        // more than 25 times will kill ios simulator
        for _ in 1...25{
            s += s
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        
        return Float(seconds)
    }
    
    // add random double numbers
    static func benchmarkAddition(range: Int) -> Float{
        let start = Date()
        
        var sum = 0.0
        for _ in 1...range{
            sum += Double.random(in: 0..<1)
        }
        
        let end = Date()
        
        let seconds = end.timeIntervalSince(start)
        
        return Float(seconds)
    }
    
    // bubblesort algorithm
    // usage: var array = [4,2,1,3]

    //print("before:",array)
    //print("after:", bubbleSort(array))
    //print("after:", bubbleSort(array, <))
    //print("after:", bubbleSort(array, >))
    static func bubbleSort<T> (_ elements: [T]) -> [T] where T: Comparable {
      return bubbleSort(elements, <)
    }

    static func bubbleSort<T> (_ elements: [T], _ comparison: (T,T) -> Bool) -> [T]  {
        var array = elements
        for i in 0..<array.count {
            for j in 1..<array.count - i{
                if comparison(array[j], array[j - 1]) {
                    let tmp = array[j - 1]
                    array[j - 1] = array[j]
                    array[j] = tmp
                }
            }
        }
      
        return array
    }
    
    // racecar as example
    static func isPalindrome(_ str: String) -> Bool {
      let strippedString = str.replacingOccurrences(of: "\\W", with: "", options: .regularExpression, range: nil)
      let length = strippedString.count

      if length > 1 {
        return palindrome(strippedString.lowercased(), left: 0, right: length - 1)
      }

      return false
    }

    static private func palindrome(_ str: String, left: Int, right: Int) -> Bool {
      if left >= right {
        return true
      }

      let lhs = str[str.index(str.startIndex, offsetBy: left)]
      let rhs = str[str.index(str.startIndex, offsetBy: right)]

      if lhs != rhs {
        return false
      }

      return palindrome(str, left: left + 1, right: right - 1)
    }
}
