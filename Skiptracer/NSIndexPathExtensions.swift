//
//  NSIndexPathExtensions.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/10/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

extension NSIndexPath {
    
    func previous() -> NSIndexPath {
        assert(self.row > 0)
        return NSIndexPath(forRow: self.row - 1, inSection: self.section)
    }
    
    func next() -> NSIndexPath {
        return NSIndexPath(forRow: self.row + 1, inSection: self.section)
    }
}
