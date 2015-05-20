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

    @NSManaged var user:         User?
    @NSManaged var activity:     Activity?
    @NSManaged var parent:       Report?
    @NSManaged var uniqueName:   String
    @NSManaged var creationDate: NSDate
    @NSManaged var startDate:    NSDate
    @NSManaged var endDate:      NSDate
    @NSManaged var breaks:       NSSet
    @NSManaged var notes:        String?
    @NSManaged var active:       Bool
    @NSManaged var isBreak:      Bool
    
    override var description: String {
        return "<\(self.uniqueName)>"
    }
    
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
}
