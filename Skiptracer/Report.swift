//
//  Report.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation
import CoreData

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
    
    var liveEndDate: NSDate {
        get {
            return self.active ? NSDate() : self.endDate
        }
        set(date) {
            self.endDate = date
        }
    }
    
    var length: Double {
        return self.liveEndDate.timeIntervalSinceDate(self.startDate)
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
        return Formatter.stringFromLength(self.length)
    }
    
    var lengthWithoutBreaksText: String {
        return Formatter.stringFromLength(self.lengthWithoutBreaks)
    }
    
    var startAndEndText: String {
        
        var startText = Formatter.clockStringFromDate(self.startDate)
        var endText = Formatter.clockStringFromDate(self.liveEndDate)
        
        /*
        if self.active {
            endText = "now"
            endText = "..."
        }
        */
        
        return startText + " - " + endText
    }
    
    var dayText: String {
        return Formatter.dayStringFromDate(self.startDate).uppercaseString
    }
    
    var monthText: String {
        return Formatter.monthStringFromDate(self.startDate).uppercaseString
    }
    
    /*
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
    */
}
