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
    @NSManaged var creationDate: Date
    @NSManaged var startDate:    Date
    @NSManaged var endDate:      Date
    @NSManaged var breaks:       NSSet
    @NSManaged var notes:        String?
    @NSManaged var active:       Bool
    @NSManaged var isBreak:      Bool
}
