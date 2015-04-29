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
    
    let nameKey = "name"
    let atomicKey = "atomic"
    let breaksKey = "breaks"
    let breakLengthKey = "breakLength"
    let breakIntervalKey = "breakInterval"
    let progressKey = "progress"
    let progressIntervalKey = "progressInterval"
    
    override var titleString: String {
        return self.activity?.name ?? "Untitled"
    }
    
    override func createCellData() -> [[SGCellData]] {
        return [
            [
                SGCellData(cellIdentifier: TEXT_FIELD_CELL_ID, title: "Name",              modelPath: nameKey)
            ],
            //[
            //    SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Atomic",            modelPath: atomicKey)
            //],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Break Alerts",      modelPath: breaksKey),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Length",      modelPath: breakLengthKey),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Interval",    modelPath: breakIntervalKey)
            ],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Progress Alerts",   modelPath: progressKey),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Progress Interval", modelPath: progressIntervalKey)
            ]
        ]
    }
    
    override func switchDidChange(toggle: UISwitch) {
        super.switchDidChange(toggle)
        self.refreshData()
    }
    
    override func enabledStateForModelPath(modelPath: String) -> Bool {
        
        if let activity = self.activity {

            switch modelPath {
                
            case breakLengthKey: fallthrough
            case breakIntervalKey:
                return activity.breaks
                
            case progressIntervalKey:
                return activity.progress
                
            default:
                return true
            }
        }
            
        return false
    }
    
    override func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        self.refreshTitle()
    }
}
