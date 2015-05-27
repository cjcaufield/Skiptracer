//
//  ReportExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/26/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

extension Report {
    
    //
    // Lengths
    //
    
    var length: Double {
        return max(0.0, self.liveEndDate.timeIntervalSinceDate(self.startDate))
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
    
    //
    // Dates For Indices
    //
    
    func breakDateForIndex(index: Int?) -> NSDate? {
        
        let offset = self.activity?.validBreakOffset
        let interval = self.activity?.validBreakInterval
        
        if index != nil && offset != nil && interval != nil {
            let length = Double(index!) * interval! + offset!
            return self.startDate.dateByAddingTimeInterval(length)
        }
        
        return nil
    }
    
    func breakEndDateForIndex(index: Int?) -> NSDate?  {
        return self.breakDateForIndex(index)?.dateByAddingTimeInterval(self.activity!.breakLength)
    }
    
    func progressDateForIndex(index: Int?) -> NSDate?  {
        
        let interval = self.activity?.validProgressInterval
        
        if index != nil && interval != nil {
            return self.startDate.dateByAddingTimeInterval(Double(index! + 1) * interval!)
        }
        
        return nil
    }
    
    //
    // Next Indices
    //
    
    func nextBreakIndex(date: NSDate) -> Int? {
        
        let offset = self.activity?.validBreakOffset
        let interval = self.activity?.validBreakInterval
        
        if offset != nil && interval != nil {
            let distance = max(0.0, date.timeIntervalSinceDate(self.startDate) - offset!)
            return Int(floor(distance / interval!))
        }
        
        return nil
    }
    
    func nextBreakEndIndex(date: NSDate) -> Int? {
        
        let offset = self.activity?.validBreakEndOffset
        let interval = self.activity?.validBreakInterval
        
        if offset != nil && interval != nil {
            let distance = max(0.0, date.timeIntervalSinceDate(self.startDate) - offset!)
            return Int(floor(distance / interval!))
        }
        
        return nil
    }
    
    func nextProgressIndex(date: NSDate) -> Int? {
        
        if let interval = self.activity?.validProgressInterval {
            let distance = max(0.0, date.timeIntervalSinceDate(self.startDate))
            return Int(floor(distance / interval))
        }
        
        return nil
    }
    
    //
    // Next Dates
    //
    
    func nextBreakDateAfter(date: NSDate) -> NSDate? {
        if let index = self.nextBreakIndex(date) {
            return self.breakDateForIndex(index)
        }
        return nil
    }
    
    func nextBreakEndDateAfter(date: NSDate) -> NSDate? {
        if let index = self.nextBreakEndIndex(date) {
            return self.breakEndDateForIndex(index)
        }
        return nil
    }
    
    func nextProgressDateAfter(date: NSDate) -> NSDate? {
        if let index = self.nextProgressIndex(date) {
            return self.progressDateForIndex(index)
        }
        return nil
    }
    
    //
    // Text
    //
    
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
    
    //
    // Debugging
    //
    
    override var description: String {
        return "<\(self.uniqueName)>"
    }
    
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
}
