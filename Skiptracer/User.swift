//
//  Skiptracer.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {

    @NSManaged var currentReport: Report?
    @NSManaged var isTestUser: Bool
    @NSManaged var activities: NSSet
    @NSManaged var reports: NSSet
}
