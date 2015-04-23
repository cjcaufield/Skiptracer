//
//  Formatter.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

private var lengthFormatter: NSDateComponentsFormatter? = nil
private var dateFormatter: NSDateFormatter? = nil
private var longDateFormatter: NSDateFormatter? = nil
private var dayFormatter: NSDateFormatter? = nil
private var monthFormatter: NSDateFormatter? = nil

class Formatter: NSObject {
   
    class func stringFromLength(length: Double) -> String {
        
        if lengthFormatter == nil {
            lengthFormatter = NSDateComponentsFormatter()
            lengthFormatter?.allowedUnits = (.CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond)
            lengthFormatter?.maximumUnitCount = 2
            lengthFormatter?.unitsStyle = .Abbreviated
            lengthFormatter?.zeroFormattingBehavior = .DropAll
        }
        
        return lengthFormatter!.stringFromTimeInterval(length) ?? ""
    }
    
    class func clockStringFromDate(date: NSDate) -> String {
        
        if dateFormatter == nil {
            dateFormatter = NSDateFormatter()
            dateFormatter?.dateFormat = "hh:mm"
        }
        
        return dateFormatter!.stringFromDate(date)
    }
    
    class func dateStringFromDate(date: NSDate) -> String {
        
        if longDateFormatter == nil {
            longDateFormatter = NSDateFormatter()
            longDateFormatter?.dateStyle = .MediumStyle
            longDateFormatter?.timeStyle = .MediumStyle
        }
        
        return longDateFormatter!.stringFromDate(date)
    }
    
    class func dayStringFromDate(date: NSDate) -> String {
        
        if dayFormatter == nil {
            dayFormatter = NSDateFormatter()
            dayFormatter?.dateStyle = .LongStyle
            dayFormatter?.timeStyle = .NoStyle
            dayFormatter?.doesRelativeDateFormatting = true
        }
        
        return dayFormatter!.stringFromDate(date)
    }
    
    class func monthStringFromDate(date: NSDate) -> String {
        
        if monthFormatter == nil {
            monthFormatter = NSDateFormatter()
            monthFormatter?.dateFormat = "EEEE"
        }
        
        return monthFormatter!.stringFromDate(date)
    }
}
