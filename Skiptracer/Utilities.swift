//
//  Utilities.swift
//  Skiptracer
//
//  Created by Colin Caufield on 5/24/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation

func removeNils<T>(array: [T?]) -> [T] {
    var newArray = [T]()
    for item in array {
        if item != nil {
            newArray.append(item!)
        }
    }
    return newArray
}

func safeCompare<T>(a: T?, b: T?, fn: (T, T) -> T) -> T? {
    let items = removeNils([a, b])
    switch items.count {
    case 1: return items[0]
    case 2: return fn(a!, b!)
    default: return items.first
    }
}

func safeMin<T: Comparable>(a: T?, b: T?) -> T? {
    return safeCompare(a, b: b, fn: min)
}

func safeMax<T: Comparable>(a: T?, b: T?) -> T? {
    return safeCompare(a, b: b, fn: max)
}

func safeEarliestDate(dates: [NSDate?]) -> NSDate? {
    var earliest: NSDate?
    for date in removeNils(dates) {
        if earliest == nil {
            earliest = date
        } else {
            earliest = earliest!.earlierDate(date)
        }
    }
    return earliest
}
