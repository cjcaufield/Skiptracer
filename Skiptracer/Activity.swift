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

    @NSManaged var user: User?
    @NSManaged var name: String
    @NSManaged var permanent: Bool
    @NSManaged var silent: Bool
    @NSManaged var atomic: Bool
    @NSManaged var breakInterval: Double
    @NSManaged var breakLength: Double
    @NSManaged var progressInterval: Double
    @NSManaged var breaks: Bool
    @NSManaged var progress: Bool
    @NSManaged var reports: NSSet
    
    /*
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
    */
}
