//
//  Array+BinarySearch.swift
//  Blocks
//
//  Created by 沈畅 on 5/18/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/26678362/how-do-i-insert-an-element-at-the-correct-position-into-a-sorted-array-in-swift
/* Usage
 let newElement = "c"
 let index = myArray.insertionIndexOf(newElement) { $0 < $1 } // Or: myArray.indexOf(c, <)
 myArray.insert(newElement, atIndex: index)
 */

extension Array {
    func insertionIndexOf(element: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], element) {
                lo = mid + 1
            } else if isOrderedBefore(element, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
    
    
    
}

extension Array where Element : Comparable {
    func binarySearch(key: Element) -> Int? {
        var lowerIndex = 0
        var upperIndex = self.count - 1
        while (true) {
            let currentIndex = (lowerIndex + upperIndex) / 2
            
            if (lowerIndex > upperIndex) {
                return nil
            } else if (self[currentIndex] == key) {
                return currentIndex
            } else {
                if (self[currentIndex] > key) {
                    upperIndex = currentIndex - 1
                } else {
                    lowerIndex = currentIndex + 1
                }
            }
        }
    }
}

extension Array where Element : Comparable {
    // Merge two sorted arrays into a sorted array, keeping one copy of duplicates.
    func sortedMerge(with other: Array) -> Array {
        let all = self + other.reversed()
        let merged = all.reduce(into: (all, [Element]())) { (result, element) in
            guard let first = result.0.first else { return }
            guard let last = result.0.last else { return }
            
            if first < last {
                result.0.removeFirst()
                result.1.append(first)
            } else if first > last {
                result.0.removeLast()
                result.1.append(last)
            } else {
                result.0.removeFirst()
                if result.0.count >= 1 {
                    result.0.removeLast()
                }
                result.1.append(first)
            }
        }.1
        
        return merged
    }
}

/*
https://stackoverflow.com/questions/39791084/swift-3-array-to-dictionary
 */

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}

