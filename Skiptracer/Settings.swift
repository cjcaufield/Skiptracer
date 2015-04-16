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
    @NSManaged var enableAlerts: Bool
    @NSManaged var currentUser: User?
}
