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
        return Formatter.stringFromLength(self.length)
    }
    
    var lengthWithoutBreaksText: String {
        return Formatter.stringFromLength(self.lengthWithoutBreaks)
    }
    
    var startAndEndText: String {
        
        let endDate = self.active ? NSDate() : self.endDate
        
        var startText = Formatter.stringFromDate(self.startDate)
        var endText = Formatter.stringFromDate(endDate)
        
        if self.active {
            //endText = "now"
            //endText = "..."
        }
        
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
