//
//  ActivityExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/26/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

extension Activity {
    
    //
    // Validity
    //
    
    var breakSettingsAreValid: Bool {
        return self.breaks && self.breakLength > 0.0 && self.breakInterval > self.breakLength
    }
    
    var progressSettingsAreValid: Bool {
        return self.progress && self.progressInterval > 0.0
    }
    
    var validBreakOffset: NSTimeInterval? {
        return (self.breakSettingsAreValid) ? self.breakInterval - self.breakLength : nil
    }
    
    var validBreakEndOffset: NSTimeInterval? {
        return (self.breakSettingsAreValid) ? self.breakInterval : nil
    }
    
    var validBreakInterval: NSTimeInterval? {
        return (self.breakSettingsAreValid) ? self.breakInterval : nil
    }
    
    var validProgressInterval: NSTimeInterval? {
        return (self.progressSettingsAreValid) ? self.progressInterval : nil
    }
    
    //
    // Text
    //
    
    var breakMessage: String {
        let lengthText = Formatter.stringFromLength(self.breakLength)
        return "Time for a \(lengthText) break."
    }
    
    var breakEndMessage: String {
        //return "Time to continue \(self.name)."
        return "Time to continue."
    }
    
    func progressMessageForIndex(index: Int) -> String {
        let lengthText = Formatter.stringFromLength(self.progressInterval * Double(index + 1))
        let activityName = self.name ?? "Untitled"
        return "You've spent \(lengthText) on \(activityName)."
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
