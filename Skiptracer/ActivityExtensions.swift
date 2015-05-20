//
//  ActivityExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/26/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

extension Activity {
    
    var breakDistance: NSTimeInterval? {
        
        if !self.breaks || self.breakInterval == 0.0 || self.breakLength == 0.0 {
            return nil
        }
        
        let value = self.breakInterval - self.breakLength
        if value < 0.0 {
            return nil
        }
        
        return value
    }
    
    var progressDistance: NSTimeInterval? {
        
        if !self.progress || self.progressInterval == 0.0 {
            return nil
        }
        
        return self.progressInterval
    }
    
    var breakMessage: String? {
        let lengthText = Formatter.stringFromLength(self.breakLength)
        return "Time for a \(lengthText) break."
    }
    
    var breakEndMessage: String? {
        let lengthText = Formatter.stringFromLength(self.breakLength)
        return "Time to continue \(self.name)."
    }
}
