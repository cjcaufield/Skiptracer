//
//  ActivityViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class ActivityViewController: SGExpandableTableViewController {
    
    var activity: Activity? { return self.object as? Activity }
    
    override func createCellData() -> [[SGCellData]] {
        return [
            [
                SGCellData(cellIdentifier: TEXT_FIELD_CELL_ID, title: "Name",              modelPath: "name")
            ],
            //[
            //    SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Atomic",            modelPath: "atomic")
            //],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Break Alerts",      modelPath: "breaks"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Length",      modelPath: "breakLength"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Interval",    modelPath: "breakInterval")
            ],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Progress Alerts",   modelPath: "progress"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Progress Interval", modelPath: "progressInterval")
            ]
        ]
    }
}
