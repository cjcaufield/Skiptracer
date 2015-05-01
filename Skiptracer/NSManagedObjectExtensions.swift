//
//  NSManagedObjectExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/30/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import CoreData

extension NSManagedObject {
    
    var uniqueString: String? {
        return self.objectID.URIRepresentation().absoluteString
    }
}
