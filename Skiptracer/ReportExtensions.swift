//
//  ReportExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/26/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import SecretKit

extension Report {
    
    //
    // Lengths
    //
    
    var length: Double {
        return max(0.0, self.liveEndDate.timeIntervalSince(self.startDate as Date))
    }
    
    var lengthWithoutBreaks: Double {
        var totalLength = self.length
        for report in self.breaks as! Set<Report> {
            let breakLength = report.length
            totalLength -= breakLength
        }
        return totalLength
    }
    
    var liveEndDate: Date {
        get {
            return self.active ? Date() : self.endDate as Date
        }
        set(date) {
            self.endDate = date
        }
    }
    
    //
    // Dates For Indices
    //
    
    func breakDateForIndex(_ index: Int?) -> Date? {
        
        let offset = self.activity?.validBreakOffset
        let interval = self.activity?.validBreakInterval
        
        if index != nil && offset != nil && interval != nil {
            let length = Double(index!) * interval! + offset!
            return self.startDate.addingTimeInterval(length)
        }
        
        return nil
    }
    
    func breakEndDateForIndex(_ index: Int?) -> Date?  {
        return self.breakDateForIndex(index)?.addingTimeInterval(self.activity!.breakLength)
    }
    
    func progressDateForIndex(_ index: Int?) -> Date?  {
        
        let interval = self.activity?.validProgressInterval
        
        if index != nil && interval != nil {
            return self.startDate.addingTimeInterval(Double(index! + 1) * interval!)
        }
        
        return nil
    }
    
    //
    // Next Indices
    //
    
    func nextBreakIndex(_ date: Date) -> Int? {
        
        let offset = self.activity?.validBreakOffset
        let interval = self.activity?.validBreakInterval
        
        if offset != nil && interval != nil {
            let distance = max(0.0, date.timeIntervalSince(self.startDate) - offset!)
            return Int(floor(distance / interval!))
        }
        
        return nil
    }
    
    func nextBreakEndIndex(_ date: Date) -> Int? {
        
        let offset = self.activity?.validBreakEndOffset
        let interval = self.activity?.validBreakInterval
        
        if offset != nil && interval != nil {
            let distance = max(0.0, date.timeIntervalSince(self.startDate) - offset!)
            return Int(floor(distance / interval!))
        }
        
        return nil
    }
    
    func nextProgressIndex(_ date: Date) -> Int? {
        
        if let interval = self.activity?.validProgressInterval {
            let distance = max(0.0, date.timeIntervalSince(self.startDate as Date))
            return Int(floor(distance / interval))
        }
        
        return nil
    }
    
    //
    // Next Dates
    //
    
    func nextBreakDateAfter(_ date: Date) -> Date? {
        if let index = self.nextBreakIndex(date) {
            return self.breakDateForIndex(index)
        }
        return nil
    }
    
    func nextBreakEndDateAfter(_ date: Date) -> Date? {
        if let index = self.nextBreakEndIndex(date) {
            return self.breakEndDateForIndex(index)
        }
        return nil
    }
    
    func nextProgressDateAfter(_ date: Date) -> Date? {
        if let index = self.nextProgressIndex(date) {
            return self.progressDateForIndex(index)
        }
        return nil
    }
    
    //
    // Text
    //
    
    var lengthText: String {
        return SGFormatter.stringFromLength(self.length)
    }
    
    var lengthWithoutBreaksText: String {
        return SGFormatter.stringFromLength(self.lengthWithoutBreaks)
    }
    
    var startAndEndText: String {
        
        let startText = SGFormatter.clockStringFromDate(self.startDate)
        let endText = SGFormatter.clockStringFromDate(self.liveEndDate)
        
        /*
        if self.active {
            endText = "now"
            endText = "..."
        }
        */
        
        return startText + " - " + endText
    }
    
    var dayText: String {
        return SGFormatter.dayStringFromDate(self.startDate).uppercased()
    }
    
    var monthText: String {
        return SGFormatter.monthStringFromDate(self.startDate).uppercased()
    }
    
    //
    // Debugging
    //
    
    override var description: String {
        return "<\(self.uniqueName)>"
    }
    
    override func validateForDelete() throws {
        print("Deleting \(self)")
    }
}
