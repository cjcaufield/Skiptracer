//
//  Settings.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/4/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation
import CoreData

class Settings: NSManagedObject {
    
    @NSManaged var enableTestUser: Bool
    @NSManaged var enableAlerts:   Bool
    @NSManaged var basicUser:      User?
    @NSManaged var testUser:       User?
    @NSManaged var currentUser:    User?
    @NSManaged var uniqueName:     String
    @NSManaged var creationDate:   NSDate
    
    override func validateForDelete(error: NSErrorPointer) -> Bool {
        println("Deleting \(self)")
        return true
    }
}
