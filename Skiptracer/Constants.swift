//
//  Constants.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/5/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

let UserWasSwitchedNotification     = "UserWasSwitchedNotification"
let AutoBreakWasStartedNotification = "AutoBreakWasStartedNotification"
let AutoBreakWasEndedNotification   = "AutoBreakWasEndedNotification"
let CloudDataDidChangeNotification  = "CloudDataDidChangeNotification"

enum ActivityType: Int {
    
    case timer
    case checkBox
    case counter
    //case Location
    
    var name: String {
        switch self {
        case .timer:    return "Timer"
        case .checkBox: return "CheckBox"
        case .counter:  return "Counter"
        //case .Location: return "Location"
        }
    }
    
    static let all = [timer, checkBox, counter, /*Location*/]
}
