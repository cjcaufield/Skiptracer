//
//  Activity.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation
import CoreData

class Activity: NSManagedObject {

    @NSManaged var user:             User?
    @NSManaged var name:             String
    @NSManaged var uniqueName:       String
    @NSManaged var creationDate:     Date
    @NSManaged var permanent:        Bool
    @NSManaged var silent:           Bool
    @NSManaged var type:             Int
    @NSManaged var breakInterval:    Double
    @NSManaged var breakLength:      Double
    @NSManaged var progressInterval: Double
    @NSManaged var breaks:           Bool
    @NSManaged var progress:         Bool
    @NSManaged var reports:          NSSet
}
