//
//  ActivityViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import SecretKit

class ActivityViewController: SGDynamicTableViewController {
    
    var activity: Activity? { return self.object as? Activity }
    
    var shouldAutoSelectNameField = false
    
    let nameKey = "name"
    let typeKey = "type"
    let breaksKey = "breaks"
    let breakLengthKey = "breakLength"
    let breakIntervalKey = "breakInterval"
    let progressKey = "progress"
    let progressIntervalKey = "progressInterval"
    
    override var titleString: String {
        return self.activity?.name ?? "Untitled"
    }
    
    override func makeTableData() -> SGTableData {
        return (
            SGTableData(
                SGSectionData(
                    SGRowData(cellIdentifier: TEXT_FIELD_CELL_ID, title: "Name",              modelPath: nameKey)
                ),
                SGSectionData(
                    SGRowData(cellIdentifier: SEGMENTED_CELL_ID,  title: "Type",              modelPath: typeKey)
                ),
                SGSectionData(
                    SGRowData(cellIdentifier: SWITCH_CELL_ID,     title: "Break Alerts",      modelPath: breaksKey),
                    SGRowData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Length",      modelPath: breakLengthKey),
                    SGRowData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Interval",    modelPath: breakIntervalKey)
                ),
                SGSectionData(
                    SGRowData(cellIdentifier: SWITCH_CELL_ID,     title: "Progress Alerts",   modelPath: progressKey),
                    SGRowData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Progress Interval", modelPath: progressIntervalKey)
                )
            )
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldAutoSelectNameField {
            let path = IndexPath(item: 0, section: 0)
            if let cell = self.tableView.cellForRow(at: path) {
                let field = cell.viewWithTag(2) as! UITextField
                field.becomeFirstResponder()
            }
            shouldAutoSelectNameField = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
    }
    
    /*
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let path = NSIndexPath(forRow: 0, inSection: section)
        let data = self.dataForIndexPath(path)
        let isTypes = (data?.modelPath == self.typeKey)
        return isTypes ? "Type" : nil
    }
    */
    
    override func configureSegmentedControl(_ control: UISegmentedControl, forModelPath path: String?) {
        if path == self.typeKey {
            control.removeAllSegments()
            for type in ActivityType.all {
                control.insertSegment(withTitle: type.name, at: type.rawValue, animated: false)
            }
        }
    }
    
    override func enabledStateForModelPath(_ modelPath: String?) -> Bool {
        
        if modelPath == nil {
            return true
        }
        
        if let activity = self.activity {

            switch modelPath! {
                
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
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        
        let data = self.dataForControl(textField)
        
        // If the name is already taken, change it to be unique.
        if data?.modelPath == nameKey {
            if let newName = textField.text, let oldName = self.activity?.name {
                if newName != oldName {
                    textField.text = AppData.shared.nextAvailableName(newName, entityName: "Activity")
                }
            }
        }
        
        super.textFieldDidEndEditing(textField)
    }
    
    override func dataModelDidChange(_ data: SGRowData) {
        
        if data.modelPath == self.nameKey {
            self.refreshTitle()
            return
        }
        
        if data.cellIdentifier == SWITCH_CELL_ID {
            self.refreshData() // Update enabled/disabled state for other controls.
            if self.activityIsCurrent {
                Notifications.shared.rescheduleAllNotificationsForCurrentReport()
            }
            return
        }
        
        if data.cellIdentifier == TIME_PICKER_CELL_ID {
            if self.activityIsCurrent {
                Notifications.shared.rescheduleAllNotificationsForCurrentReport()
            }
        }
    }
    
    var activityIsCurrent: Bool {
        if let currentActivity = Notifications.shared.currentReport?.activity {
            if self.activity == currentActivity {
                return true
            }
        }
        return false
    }
    
    func cloudDataDidChange(_ note: Notification) {
        self.refreshData()
    }
}
