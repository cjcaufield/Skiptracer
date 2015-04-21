//
//  Report.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation
import CoreData

var lengthFormatter: NSDateComponentsFormatter? = nil
var durationFormatter: NSDateIntervalFormatter? = nil
var startAndEndFormatter: NSDateFormatter? = nil

class Report: NSManagedObject {

    @NSManaged var user: User?
    @NSManaged var activity: Activity?
    @NSManaged var parent: Report?
    @NSManaged var breaks: NSSet
    @NSManaged var startDate: NSDate
    @NSManaged var endDate: NSDate
    @NSManaged var notes: String?
    @NSManaged var active: Bool
    @NSManaged var isBreak: Bool
    
    var length: Double {
        let nowOrEndDate = (self.active) ? NSDate() : self.endDate
        return nowOrEndDate.timeIntervalSinceDate(self.startDate)
    }
    
    var lengthWithoutBreaks: Double {
        var totalLength = self.length
        for report in self.breaks as! Set<Report> {
            let breakLength = report.length
            totalLength -= breakLength
        }
        return totalLength
    }
    
    var lengthText: String {
        return self.stringFromLength(self.length)
    }
    
    var lengthWithoutBreaksText: String {
        return self.stringFromLength(self.lengthWithoutBreaks)
    }
    
    func stringFromLength(length: Double) -> String {
        
        if lengthFormatter == nil {
            lengthFormatter = NSDateComponentsFormatter()
            lengthFormatter?.allowedUnits = (.CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond)
            lengthFormatter?.maximumUnitCount = 2
            lengthFormatter?.unitsStyle = .Abbreviated
            lengthFormatter?.zeroFormattingBehavior = .DropAll
        }
        
        if let text = lengthFormatter?.stringFromTimeInterval(length) {
            return text
        }
        
        return ""
    }
    
    /*
    var durationText: String {
        
        if durationFormatter == nil {
            durationFormatter = NSDateIntervalFormatter()
            durationFormatter?.dateStyle = .NoStyle
            durationFormatter?.timeStyle = .ShortStyle
            //durationFormatter?.allowedUnits = (.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond)
            //durationFormatter?.unitsStyle = .Positional
            //durationFormatter?.zeroFormattingBehavior = .Default
        }
        
        //if let text = durationFormatter?.stringFromTimeInterval(self.length) {
        let nowOrEndDate = (self.active) ? NSDate() : self.endDate
        if let text = durationFormatter?.stringFromDate(self.startDate, toDate: nowOrEndDate) {
            return text
        }
        
        return ""
    }
    */
    
    var startAndEndText: String {
        
        let endDate = self.active ? NSDate() : self.endDate
        
        if startAndEndFormatter == nil {
            startAndEndFormatter = NSDateFormatter()
            startAndEndFormatter?.dateFormat = "hh:mm"
        }
        
        var startText = startAndEndFormatter?.stringFromDate(self.startDate)
        var endText = startAndEndFormatter?.stringFromDate(endDate)
        
        if self.active {
            //endText = "now"
            //endText = "..."
        }
        
        if startText != nil && endText != nil {
            return startText! + " - " + endText!
        }
        
        return ""
    }
    
    var dayText: String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        //formatter.dateFormat = "EEEE"
        formatter.doesRelativeDateFormatting = true
        //formatter.dateStyle = lkjds
        //formatter.timeStyle = dlkjd
        let text = formatter.stringFromDate(self.startDate).uppercaseString
        return text
    }
    
    var monthText: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE"
        let text = formatter.stringFromDate(self.startDate)
        return text
    }
    
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
}
