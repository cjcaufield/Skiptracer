//
//  ReportExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/26/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

// Date and Time Extensions

extension Report {
    
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
    
    var liveEndDate: NSDate {
        get {
            return self.active ? NSDate() : self.endDate
        }
        set(date) {
            self.endDate = date
        }
    }
    
    var nextBreakDate: NSDate? {
        if let interval = self.activity?.breakDistance {
            return self.startDate.dateByAddingTimeInterval(interval)
        } else {
            return nil
        }
    }
}

// Text Extensions

extension Report {
    
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
